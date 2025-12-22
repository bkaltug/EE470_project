import torch
import torch.nn.functional as F
from torchvision import transforms
from PIL import Image
import os
import random
import matplotlib.pyplot as plt
from data_nn import TrafficSignClassifier, device 

# load model
MODEL_PATH = './models/simple_cnn_traffic_sign.pth'
NUM_CLASSES = 29  # class number

model = TrafficSignClassifier(num_classes=NUM_CLASSES)
model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
model.to(device)
model.eval()  # for test

# class labels
with open('./dataset/valid/_classes.txt', 'r') as f:
    class_names = [line.strip() for line in f.readlines()]

if len(class_names) != NUM_CLASSES:
    raise ValueError(f"Number of classes in classes.txt ({len(class_names)}) does not match NUM_CLASSES ({NUM_CLASSES})")

# load test
TEST_DIR = './dataset/valid' 
all_images = [img for img in os.listdir(TEST_DIR) if img.endswith(('.jpg', '.png'))]

if not all_images:
    raise FileNotFoundError(f"No images found in {TEST_DIR}")

# random image
img_name = random.choice(all_images)
#img_name = "b.jpg"
img_path = os.path.join(TEST_DIR, img_name)
print(f"\nSelected image: {img_name}")

test_transform = transforms.Compose([
    transforms.Resize((30, 30)),  #same size train
    transforms.ToTensor(),
])

image = Image.open(img_path).convert('RGB')
image_tensor = test_transform(image).unsqueeze(0).to(device)  # (1, 3, 30, 30)

# predict
with torch.no_grad():
    outputs = model(image_tensor)
    probs = F.softmax(outputs, dim=1)
    predicted_class = torch.argmax(probs, dim=1).item()
    predicted_label = class_names[predicted_class]

# show
print(f"Predicted class ID: {predicted_class}")
print(f"Predicted label: {predicted_label}")
print(f"Class probabilities: {probs.cpu().numpy()}")

try:
    plt.imshow(image)
    plt.title(f"Predicted: {predicted_label}")
    plt.axis('off')
    plt.show()
except ImportError:
    print("matplotlib not installed; skipping image display.")
