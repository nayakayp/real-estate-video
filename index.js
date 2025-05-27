"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const child_process_1 = require("child_process");
const path_1 = __importDefault(require("path"));
const app = (0, express_1.default)();
const port = 3000; // Or any port you prefer
// Middleware to parse JSON request bodies
app.use(express_1.default.json());
app.get("/", (req, res) => {
    res.send("Hello, world!");
});
app.post("/cleanup", (req, res) => {
    const { propertyFilename } = req.body;
    // Basic validation
    if (!propertyFilename) {
        return res.status(400).send("Missing required parameters: fileName");
    }
    const command = `./cleanup.sh "${propertyFilename}"`;
    (0, child_process_1.exec)(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return res.status(500).send(`Failed to cleanup: ${stderr}`);
        }
        console.log(`stdout: ${stdout}`);
        console.error(`stderr: ${stderr}`);
        return res.status(200).json({
            message: "Cleanup complete.",
            data: null,
        });
    });
});
app.get("/download", (req, res) => {
    return res.download("mangga-raya-lybb.mp4", (downloadErr) => {
        if (downloadErr) {
            console.error(`Error sending file: ${downloadErr}`);
            // If download fails after successful generation, log the error but still indicate success
            // or send a different status depending on desired behavior.
            // For now, we'll just log the error.
        }
        else {
            console.log(`Sent file`);
        }
    });
});
app.post("/generate-video", (req, res) => {
    const { propertyFilename, propertyType, propertyPrice, propertyAddress, propertyCity, propertyBedroom, propertyBathroom, propertySquareMeter, propertyWebsite, propertyPhone, propertyEmail, photoUrls, } = req.body;
    // Basic validation
    if (!propertyFilename ||
        !propertyType ||
        !propertyPrice ||
        !propertyAddress ||
        !propertyCity ||
        !propertyBedroom ||
        !propertyBathroom ||
        !propertySquareMeter ||
        !propertyWebsite ||
        !propertyPhone ||
        !propertyEmail ||
        !photoUrls ||
        !Array.isArray(photoUrls) ||
        photoUrls.length === 0) {
        return res
            .status(400)
            .send("Missing required parameters or photoUrls is empty.");
    }
    // Construct the command
    // Ensure arguments with spaces are quoted
    const command = `./generate.sh "${propertyFilename}" "${propertyType}" "${propertyPrice}" "${propertyAddress}" "${propertyCity}" "${propertyBedroom}" "${propertyBathroom}" "${propertySquareMeter}" "${propertyWebsite}" "${propertyPhone}" "${propertyEmail}" ${photoUrls.map((url) => `"${url}"`).join(" ")}`;
    console.log(`Executing command: ${command}`);
    (0, child_process_1.exec)(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return res.status(500).send(`Failed to generate video: ${stderr}`);
        }
        console.log(`stdout: ${stdout}`);
        console.error(`stderr: ${stderr}`);
        // Assuming the script outputs the video file path to stdout
        const videoFilePath = stdout.trim();
        const absoluteVideoPath = path_1.default.join(__dirname, "..", videoFilePath); // Adjust path as needed
        // return res.status(200).json({
        //   message: "Video generation started successfully.",
        //   data: `${propertyFilename}.mp4`,
        // });
        return res.download(`${propertyFilename}.mp4`, (downloadErr) => {
            if (downloadErr) {
                console.error(`Error sending file: ${downloadErr}`);
                // If download fails after successful generation, log the error but still indicate success
                // or send a different status depending on desired behavior.
                // For now, we'll just log the error.
            }
            else {
                console.log(`Sent file: ${propertyFilename}.mp4`);
            }
        });
    });
});
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});
