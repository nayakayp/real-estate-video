import express from "express";
import { exec } from "child_process";
import path from "path";

const app = express();
const port = 3000; // Or any port you prefer

// Middleware to parse JSON request bodies
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Hello, world!");
});

app.post("/cleanup", (req: any, res: any) => {
  const { propertyFilename } = req.body;

  // Basic validation
  if (!propertyFilename) {
    return res.status(400).send("Missing required parameters: fileName");
  }

  const command = `./cleanup.sh "${propertyFilename}"`;

  exec(command, (error, stdout, stderr) => {
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
  return res.download("mangga-raya-lybb.mp4", (downloadErr: any) => {
    if (downloadErr) {
      console.error(`Error sending file: ${downloadErr}`);
      // If download fails after successful generation, log the error but still indicate success
      // or send a different status depending on desired behavior.
      // For now, we'll just log the error.
    } else {
      console.log(`Sent file`);
    }
  });
});

app.post("/generate-video", (req: any, res: any) => {
  const {
    propertyFilename,
    propertyType,
    propertyPrice,
    propertyAddress,
    propertyCity,
    propertyBedroom,
    propertyBathroom,
    propertySquareMeter,
    propertyWebsite,
    propertyPhone,
    propertyEmail,
    photoUrls,
  } = req.body;

  // Basic validation
  if (
    !propertyFilename ||
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
    photoUrls.length === 0
  ) {
    return res
      .status(400)
      .send("Missing required parameters or photoUrls is empty.");
  }

  // Construct the command
  // Ensure arguments with spaces are quoted
  const command = `./generate.sh "${propertyFilename}" "${propertyType}" "${propertyPrice}" "${propertyAddress}" "${propertyCity}" "${propertyBedroom}" "${propertyBathroom}" "${propertySquareMeter}" "${propertyWebsite}" "${propertyPhone}" "${propertyEmail}" ${photoUrls.map((url) => `"${url}"`).join(" ")}`;

  console.log(`Executing command: ${command}`);

  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      return res.status(500).send(`Failed to generate video: ${stderr}`);
    }
    console.log(`stdout: ${stdout}`);
    console.error(`stderr: ${stderr}`);

    // Assuming the script outputs the video file path to stdout
    const videoFilePath = stdout.trim();
    const absoluteVideoPath = path.join(__dirname, "..", videoFilePath); // Adjust path as needed

    // return res.status(200).json({
    //   message: "Video generation started successfully.",
    //   data: `${propertyFilename}.mp4`,
    // });
    return res.download(`${propertyFilename}.mp4`, (downloadErr: any) => {
      if (downloadErr) {
        console.error(`Error sending file: ${downloadErr}`);
        // If download fails after successful generation, log the error but still indicate success
        // or send a different status depending on desired behavior.
        // For now, we'll just log the error.
      } else {
        console.log(`Sent file: ${propertyFilename}.mp4`);
      }
    });
  });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
