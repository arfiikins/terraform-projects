#!/bin/bash

#install apache
yum update -y
yum install httpd -y

#enable and start apache
systemctl enable httpd
systemctl start httpd

#input code
echo '<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Philippines Tourist Spots</title>
        <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700&display=swap" rel="style">
    </head>
    <body>
        <header>Top Tourist Spots in the Philippines</header>
        <div class="container">
            <section class="section scroll-reveal">
                <img src="https://www.shangri-la.com/-/media/Shangri-La/boracay_boracayresort/about/2023_SLBO_Explore-Boracay.jpg" alt="Boracay">
                <div class="content">
                    <h2>Boracay</h2>
                    <p>Famous for its white-sand beaches and vibrant nightlife.</p>
                </div>
            </section>
            <section class="section scroll-reveal">
                <img src="https://upload.wikimedia.org/wikipedia/commons/1/13/Kayangan_Lake%2C_Coron_-_Palawan.jpg" alt="Palawan">
                <div class="content">
                    <h2>Palawan</h2>
                    <p>Known for its crystal-clear waters and stunning limestone cliffs.</p>
                </div>
            </section>
            <section class="section scroll-reveal">
                <img src="https://cdn.i-scmp.com/sites/default/files/d8/images/canvas/2024/03/16/e44c5c6a-e323-4f60-bd43-022d4500b396_1f97d40f.jpg" alt="Chocolate Hills">
                <div class="content">
                    <h2>Chocolate Hills</h2>
                    <p>Unique geological formations in Bohol.</p>
                </div>
            </section>
            <section class="section scroll-reveal">
                <img src="https://www.blisssiargao.com/wp-content/uploads/2023/07/Siargao-Beaches-705x530.jpg" alt="Siargao">
                <div class="content">
                    <h2>Siargao</h2>
                    <p>The surfing capital of the Philippines.</p>
                </div>
            </section>
        </div>
        <footer>© 2024 Philippines Tourist Spots</footer>    <div id="chatbot">
            <div id="chatbot-header">
                <span>Chat with us!</span>
                <button id="close-chatbot">x</button>
            </div>
            <div id="chatbot-body">
                <div class="chatbot-message">Hello! How can I help you today?</div>
            </div>
            <input type="text" id="chatbot-input" placeholder="Type a message...">
        </div>
        <button id="chatbot-button">Chat</button>
        <script src="script.js"></script>
    </body>
<style>
/* Importing Google Font */
@import url("https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700&display=swap");

body {
    font-family: "Montserrat", sans-serif;
    margin: 0;
    padding: 0;
    overflow-x: hidden;
    background-color: #f0f0f0;
    scroll-behavior: smooth;
}

header {
    width: 100%;
    background: #2c3e50;
    color: #ecf0f1;
    text-align: center;
    padding: 20px 0;
    font-size: 2.5em;
    position: fixed;
    top: 0;
    z-index: 1000;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 100px 20px;
    margin-top: 80px;
}

.section {
    display: flex;
    align-items: center;
    justify-content: space-around;
    padding: 100px 20px;
    opacity: 0;
    transform: translateY(100px);
    transition: all 0.5s ease-out;
    margin-top: 80px;
    background-color: #fff;
    border-radius: 15px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.2s ease, box-shadow 0.2s ease; 
}

.section.active {
    opacity: 1;
    transform: translateY(0);
}

.section:hover {
    transform: scale(1.05);
    box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
}

.section img {
    width: 100%;
    max-width: 400px;
    height: auto;
    border-radius: 15px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.section .content {
    max-width: 600px;
    text-align: left;
    padding: 0 20px;
}

.section h2 {
    font-size: 2em;
    margin: 0 0 10px;
    color: #2c3e50;
}

.section p {
    font-size: 1.2em;
    color: #666;
}

footer {
    width: 100%;
    background: #2c3e50;
    color: #ecf0f1;
    text-align: center;
    padding: 10px 0;
    position: fixed;
    bottom: 0;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.2);
}

#chatbot {
    position: fixed;
    bottom: 90px;
    right: 30px;
    width: 300px;
    background-color: #fff;
    border-radius: 10px;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
    display: none;
    flex-direction: column;
}

#chatbot-header {
    background-color: #2c3e50;
    color: #ecf0f1;
    padding: 10px;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

#chatbot-body {
    padding: 10px;
    flex: 1;
    overflow-y: auto;
}

#chatbot-input {
    border: none;
    border-top: 1px solid #ddd;
    padding: 10px;
    border-bottom-left-radius: 10px;
    border-bottom-right-radius: 10px;
    outline: none;
}

#chatbot-button {
    position: fixed;
    bottom: 30px;
    right: 30px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    background-color: #2c3e50;
    color: #ecf0f1;
    border: none;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
    cursor: pointer;
    font-size: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
}
</style>
<script>
document.addEventListener("DOMContentLoaded", function () {
    const elements = document.querySelectorAll(".scroll-reveal");
    const chatbotButton = document.getElementById("chatbot-button");
    const chatbot = document.getElementById("chatbot");
    const closeChatbotButton = document.getElementById("close-chatbot");

    const observerOptions = {
        root: null,
        rootMargin: "0px",
        threshold: 0.1
    };

    const observerCallback = (entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add("active");
                observer.unobserve(entry.target);
            }
        });
    };

    const observer = new IntersectionObserver(observerCallback, observerOptions);

    elements.forEach(element => {
        observer.observe(element);
    });

    chatbotButton.addEventListener("click", () => {
        chatbot.style.display = "flex";
        chatbotButton.style.display = "none";
    });

    closeChatbotButton.addEventListener("click", () => {
        chatbot.style.display = "none";
        chatbotButton.style.display = "block";
    });
});

</script>
</html>
' > ~/index.html
mv ~/index.html /var/www/html/