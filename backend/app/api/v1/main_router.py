from fastapi import UploadFile, File, Query, APIRouter
from fastapi.responses import JSONResponse, StreamingResponse
from ultralytics import YOLO
import torch, io
from PIL import Image
import numpy as np


main_router = APIRouter()


DEVICE = 0 if torch.cuda.is_available() else "cpu"
MODEL_PATH = r"C:\Users\Admin\Desktop\YoloTrain\p\runs\segment\train3\weights\best.pt"
model = YOLO(MODEL_PATH)
NAMES = model.model.names if hasattr(model, "model") and hasattr(model.model, "names") else model.names

@main_router.get("/health")
def health():
    return {"status": "ok", "device": DEVICE, "classes": NAMES}

@main_router.post("/predict")
async def predict(
    file: UploadFile = File(..., description="Изображение (jpg/png)"),
    conf: float = Query(0.25, ge=0.0, le=1.0),
    imgsz: int = Query(640, ge=64, le=2048),
    return_image: bool = Query(False, description="Вернуть размеченное изображение вместо JSON"),
):
    # читаем файл
    image_bytes = await file.read()
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    # инференс
    results = model.predict(
        source=img,
        imgsz=imgsz,
        conf=conf,
        device=DEVICE,
        verbose=False,
        save=False
    )
    r = results[0]  # один кадр

    # если просили визуализацию — вернём PNG
    if return_image:
        plotted = r.plot()
        # конвертируем BGR->RGB и кодируем в PNG
        import cv2
        plotted_rgb = cv2.cvtColor(plotted, cv2.COLOR_BGR2RGB)
        ok, buf = cv2.imencode(".png", plotted_rgb)
        if not ok:
            return JSONResponse({"error": "failed to encode image"}, status_code=500)
        return StreamingResponse(io.BytesIO(buf.tobytes()), media_type="image/png")

    # иначе соберём структурированный JSON
    boxes = []
    if r.boxes is not None and r.boxes.xyxy is not None:
        xyxy = r.boxes.xyxy.cpu().numpy()
        cls = r.boxes.cls.cpu().numpy().astype(int)
        confs = r.boxes.conf.cpu().numpy()
        for b, c, s in zip(xyxy, cls, confs):
            boxes.append({
                "xyxy": [float(round(x, 2)) for x in b.tolist()],
                "class_id": int(c),
                "class_name": str(NAMES.get(int(c), str(c))),
                "conf": float(round(s, 3)),
            })

    polygons = []
    mask_areas = []
    if getattr(r, "masks", None) is not None and r.masks is not None:
        # полигоны в пикселях
        for poly in r.masks.xy:
            poly_list = [[float(round(x, 2)), float(round(y, 2))] for x, y in poly.tolist()]
            polygons.append(poly_list)
        # площадь масок (доля кадра)
        m = r.masks.data  # [N, H, W] тензор bool/float
        H, W = m.shape[-2:]
        areas = m.float().sum(dim=(1, 2)).cpu().numpy() / float(W * H)
        mask_areas = [float(round(a, 5)) for a in areas.tolist()]

    # сводка по классам
    summary = {}
    for b in boxes:
        k = b["class_name"]
        summary[k] = summary.get(k, 0) + 1

    return {
        "image_size": imgsz,
        "conf_threshold": conf,
        "num_objects": len(boxes),
        "summary_counts": summary,
        "boxes": boxes,
        "polygons": polygons,
        "mask_area_ratio": mask_areas
    }