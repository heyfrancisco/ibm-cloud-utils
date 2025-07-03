#!/usr/bin/env node

const { exec } = require("child_process");
const fs = require("fs");
const { promisify } = require("util");

const execAsync = promisify(exec);

async function pingAndLog(destination, label) {
  console.log(`Starting ping from Lisbon to ${label}...`);

  try {
    const { stdout, stderr } = await execAsync(
      `ping -c 15 ${destination} 2>&1`,
    );
    const output = stdout || stderr;
    const roundTripLines = output
      .split("\n")
      .filter((line) => line.includes("round"));

    let result = `\nFrom Lisbon to ${label}\n`;
    roundTripLines.forEach((line) => {
      result += line + "\n";
    });

    console.log(`Ping to ${label} completed.`);
    return result;
  } catch (error) {
    console.error(`Error pinging ${label}:`, error.message);
    return `\nFrom Lisbon to ${label}\nError: ${error.message}\n`;
  }
}

async function logPerformance() {
  const logFile = "lisboa.log";
  console.log("Starting log performance check...");

  try {
    let logContent = new Date().toString() + "\n";

    logContent += await pingAndLog(
      "s3.eu-es.cloud-object-storage.appdomain.cloud",
      "Madrid",
    );
    logContent += await pingAndLog(
      "s3.eu-de.cloud-object-storage.appdomain.cloud",
      "Frankfurt",
    );
    logContent += "\n\n";

    fs.appendFileSync(logFile, logContent);
    console.log(`Log performance check completed and saved to ${logFile}.`);
  } catch (error) {
    console.error("Error in log performance:", error.message);
  }
}

// Execute the script
logPerformance();
