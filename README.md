
# SmolScope

**SmolScope** is a Flutter-based mobile application that lets you interact with your surroundings using vision-language models — completely offline.  
The app captures camera frames and sends them to a locally hosted [SmolVLM](https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF) model via [llama.cpp](https://github.com/ggml-org/llama.cpp), which returns natural language descriptions in real-time.

Since this is just a POC, the UI is as basic as it gets ⚠️ — focused on functionality over polish.

## 🔍 What it does

- Takes real-time photos from the mobile camera
- Sends each image along with a prompt to a local SmolVLM server
- Receives natural language responses and displays them in the app
- Fully functional over local network — no internet required

---




### 🛠️ Setup Steps

1.  **Clone the Repo**
    
`git clone https://github.com/iamthejahid/smolscope.git`
`cd smolscope` 

----------

2.  **Install `llama.cpp`**
    

-   Download the latest release matches your spec: [https://github.com/ggml-org/llama.cpp/releases](https://github.com/ggml-org/llama.cpp/releases)
-   Create a directory and unzip it:
    
`mkdir -p ~/llama `
`# Unzip the downloaded file into ~/llama` 

----------

3.  **Start the `llama.cpp` Server**
 
`cd ~/llama
./llama-server --host 0.0.0.0 --port 8080 -hf ggml-org/SmolVLM-500M-Instruct-GGUF` 
Note: we are hosting at 0.0.0.0 so that any device from the local network can access it.
Also, this command will take some time in first run, cause it will automatically download the model. 
you can tweak that, and use your model from [here](https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/tree/main).

----------

4.  **Configure IP in Flutter App**
    

-   Make sure your mobile device and the host machine are on the same Wi-Fi network
-   Find your machine’s local IP (e.g., `192.168.1.106`)
-   In the app source code, update this line:
    

dart

CopyEdit

`final String _baseUrl = 'http://192.168.1.106:8080';` 

----------

6.  **Run the App**
    

bash

CopyEdit

`flutter pub get
flutter run` 

> That’s it. You can now see your mobile app sending images to the local SmolVLM server and receiving natural language descriptions in real time.

----
## 📽️ Preview

![Demo](assets/demo.gif)

