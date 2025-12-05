import torch
import torch.nn as nn
import numpy as np
from PIL import Image
import torch.nn.functional as F
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from torchvision import transforms

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu") #we use gpu, for fast

#build neural network
class TrafficSignClassifier(nn.Module):
    def __init__(self, num_classes):
        super(TrafficSignClassifier, self).__init__()
        
        #conv. layer
        self.conv1 = nn.Conv2d(in_channels=3, out_channels=32, kernel_size=5) #3-> RGB, 32--> catch up side, corner , 5<5 area, bigger area, few details
        
        #second conv. layer
        self.conv2 = nn.Conv2d(in_channels=32, out_channels=64, kernel_size=3) #64--> catch up symbols, letters, 3x3 area, more details
        
        # Max-Pooling layer
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # Dropout layer- for organized, non-overfitting
        self.dropout = nn.Dropout(p=0.5)
        
        # Fully Connected Layer
        self.fc1 = nn.Linear(64 * 5 * 5, 128) #predict value, change something, 64 çıktım var 5x5'te ilkb boyutum, 128 orta boy veriler için iyi bir tespittir
        self.fc2 = nn.Linear(128, num_classes) # output layer
  
    def forward(self, x):
        # -> conv 1 -> ReLU -> MaxPool
        x = self.pool(F.relu(self.conv1(x)))
        
        # -> conv 2 -> ReLU -> MaxPool
        x = self.pool(F.relu(self.conv2(x)))
        
        #Flatten  layer
        x = torch.flatten(x, 1) #1D dim
        
        # -> Dropout -> Linear 1 -> ReLU
        x = self.dropout(x)
        x = F.relu(self.fc1(x))
        
        # -> Linear 2 layer
        x = self.fc2(x)
        
        return x

#start model
NUM_CLASSES = 29 #check train--> classes

model = TrafficSignClassifier(NUM_CLASSES).to(device)

# Loss Func.
criterion = nn.CrossEntropyLoss() 

# Optimizastion
optimizer = optim.Adam(model.parameters(), lr=0.001)


# train
def train_model(model, dataloader, criterion, optimizer, num_epochs=10):
    for epoch in range(num_epochs):  
        running_loss = 0.0
        correct=0
        total=0
        for i, data in enumerate(dataloader, 0):
            # find labels
            inputs, labels = data
            inputs, labels = inputs.to(device), labels.to(device)

            #set zero for gradyan
            optimizer.zero_grad()

            # Forward Pass
            outputs = model(inputs)
            
            #Calculate loss
            loss = criterion(outputs, labels)
            
            # Backward Pass- optimizasyon
            loss.backward()
            optimizer.step()

            #for print loss
            running_loss += loss.item()
            
            #for print accuracy
            _, predicted = torch.max(outputs.data, 1)  
            total += labels.size(0)                   
            correct += (predicted == labels).sum().item() 
            

        accuracy = 100 * correct / total
        print(f'Epoch {epoch + 1}, Loss: {running_loss / len(dataloader):.4f}, Accuracy: %{accuracy:.2f}')

    print('Train is succeSsfully.')


