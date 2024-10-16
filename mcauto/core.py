import cv2
import numpy as np
import pyautogui
import pytesseract
import time
import re  # 导入正则表达式模块

# 下面这行的路径改成自己安装的tesseract的路径
pytesseract.pytesseract.tesseract_cmd = r'D:\Tesseract-OCR\tesseract.exe'

# 聊天栏区域，依据个人屏幕分辨率和游戏界面调整
chat_region = (100, 800, 1200, 200)  # (x, y, width, height)
last_message = None  # 用于存储上一次的聊天消息

def capture_chat_area():
    """截取聊天栏区域并返回图像"""
    screenshot = pyautogui.screenshot(region=chat_region)
    return np.array(screenshot)

def recognize_chat_message(image):
    """从聊天区域图像中识别并提取消息"""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    text = pytesseract.image_to_string(thresh, config='--psm 6')
    lines = text.strip().split('\n')
    return lines

def parse_message(message):
    """解析消息并返回一个字典，包含type, player和message字段"""
    player = ""
    message_content = ""

    # 处理悄悄话消息
    if "悄悄地对你说" in message:
        match = re.findall(r'(\w+) 悄悄地对你说: (.+)', message)
        if match:
            player, message_content = match[0]
            return {
                "type": "whisper",
                "player": player,
                "message": message_content
            }

    # 处理普通聊天消息
    match = re.findall(r'"""(\w+)\n(.+)"""', message, re.DOTALL)
    if match:
        player, message_content = match[0]
        return {
            "type": "chat",
            "player": player,
            "message": message_content.strip()  # 去除多余的空格
        }
    
    # 处理进服消息
    if "加入了游戏" in message:
        player = re.findall(r'(\w+) 加入了游戏', message)
        if player:
            return {
                "type": "join",
                "player": player[0],
                "message": ""
            }

    # 处理退服消息
    if "退出了游戏" in message:
        player = re.findall(r'(\w+) 退出了游戏', message)
        if player:
            return {
                "type": "leave",
                "player": player[0],
                "message": ""
            }
    
    return None  # 没有匹配到任何内容

def handle_message(message):
    """处理聊天消息"""
    global last_message

    message = message.strip()

    if message != last_message:
        last_message = message
        result = parse_message(message)  # 解析消息
        
        if result:
            # 打印格式化的输出
            print(f"消息类型: {result['type']}, 玩家: {result['player']}, 内容: {result['message']}")

# 主循环部分
def main():
    global last_message

    try:
        while True:
            image = capture_chat_area()  # 捕捉聊天区域
            messages = recognize_chat_message(image)  # 识别聊天消息

            if messages:
                # 获取最后一条消息并处理
                last_line = messages[-1]  # 最新的聊天行
                handle_message(last_line)  # 处理消息
                
            time.sleep(0.2)  # 每0.2秒检查一次
    except KeyboardInterrupt:
        print("程序结束")

if __name__ == "__main__":
    main()
