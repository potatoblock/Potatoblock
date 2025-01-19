#Author:Yeah(QQ:1246517085)
import uiautomator2
from PIL import Image
import pytesseract
import os
import websocket
import json
import threading
import base64
from io import BytesIO

def image_to_base64(image):
    # 将 PIL 图像转换为字节流
    buffered = BytesIO()
    image.save(buffered, format="JPEG")
    # 将字节流编码为 base64 字符串
    img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')
    return img_str

# 连接到设备
d = uiautomator2.connect() # 自己写设备ID

# WebSocket 连接信息
ws_url = "ws://0.0.0.0:8081/" # CQHTTP 正向WS地址
access_token = "114514" # CQHTTP 连接密钥
group_id = 593301642 # 群号

# 要查找的 RGB 值
target_rgb = (5, 6, 11) # 聊天框栏的颜色
last_text = None

# 定义要裁剪的区域（左上角x, 左上角y, 右下角x, 右下角y）
left, top, right, bottom = 247, 90, 1185, 915

# WebSocket 连接函数
def connect_websocket():
    ws = websocket.WebSocket()
    ws.connect(ws_url, header={"Authorization": f"Bearer {access_token}"})
    return ws

# 发送群消息的函数
def send_group_msg(ws, group_id, message):
    data = {
        "action": "send_group_msg",
        "params": {
            "group_id": group_id,
            "message": message
        }
    }
    ws.send(json.dumps(data))

# 聊天记录采集函数
def collect_chat_records(ws):
    global last_text
    print("开始")
    while True:
        # 截取整个屏幕
        screen = d.screenshot()

        # 裁剪图片
        cropped_img = screen.crop((left, top, right, bottom))

        # 获取裁剪后图片的尺寸
        width, height = cropped_img.size

        # 存储分割线的位置
        split_positions = []

        # 遍历图片的最右边一列
        for y in range(height):
            # 获取当前像素的 RGB 值
            pixel = cropped_img.getpixel((width - 1, y))
            # 检查是否匹配目标 RGB 值
            if pixel == target_rgb:
                split_positions.append(y)

        # 分割图片并识别文字
        try:
            last_y = split_positions[-1]
        except Exception:
            continue

        def say():
            global last_text
            # 如果还有剩余的部分，进行文字识别
            if last_y < height:
                box = (0, last_y, width, height)
                record = cropped_img.crop(box)
                text = pytesseract.image_to_string(record, lang='chi_sim', config='--psm 3')
                if last_text == text or not text:
                    return
                last_text = text
                print(text)
                message = [{
                    "type": "image",
                    "data": {
                        "file": "base64://" + image_to_base64(record)
                    }
                },
                {
                    "type": "text",
                    "data": {
                        "text": text
                    }
                }]
               
                send_group_msg(ws, group_id, message)
        threading.Thread(target=say, args=(), daemon=True).start()

# 主函数
def main():
    ws = connect_websocket()
    threading.Thread(target=collect_chat_records, args=(ws,), daemon=True).start()
    while True:
        # 保持主进程运行，避免 WebSocket 连接断开
        pass

if __name__ == "__main__":
    main()
