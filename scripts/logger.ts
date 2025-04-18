import chalk from 'chalk';
import { createLogger, format, transports, Logger as WinstonLogger } from 'winston';
import path from 'path';
import fs from 'fs';

// Custom format for console output with emojis
const consoleFormat = format.printf(({ level, message, timestamp }) => {
  return `${timestamp} ${level}: ${message}`;
});

export class Logger {
  private static instance: Logger;
  private winstonLogger: WinstonLogger;
  private initialized: boolean = false;

  private constructor() {
    // Private constructor to prevent direct instantiation
  }

  public static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  public initialize(options: { 
    logsDir?: string;
    maxSize?: number;
    maxFiles?: number;
    level?: string;
  } = {}): void {
    if (this.initialized) {
      return; // Already initialized
    }

    const {
      logsDir = path.join(process.cwd(), 'logs'),
      maxSize = 5242880, // 5MB
      maxFiles = 5,
      level = 'info'
    } = options;

    // Create logs directory if it doesn't exist
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir);
    }

    // Create a Winston logger
    this.winstonLogger = createLogger({
      level,
      format: format.combine(
        format.timestamp(),
        format.json()
      ),
      transports: [
        // Console transport with colors and emojis
        new transports.Console({
          format: format.combine(
            format.colorize(),
            format.timestamp(),
            consoleFormat
          )
        }),
        // File transport with rotation
        new transports.File({
          filename: path.join(logsDir, 'error.log'),
          level: 'error',
          maxsize: maxSize,
          maxFiles: maxFiles,
        }),
        new transports.File({
          filename: path.join(logsDir, 'combined.log'),
          maxsize: maxSize,
          maxFiles: maxFiles,
        })
      ]
    });

    this.initialized = true;
  }

  private ensureInitialized(): void {
    if (!this.initialized) {
      this.initialize(); // Initialize with defaults if not already initialized
    }
  }

  public success(message: string): void {
    this.ensureInitialized();
    const formattedMessage = `✅  ${message}`;
    this.winstonLogger.info(formattedMessage);
  }

  public info(message: string): void {
    this.ensureInitialized();
    const formattedMessage = `ℹ️  ${message}`;
    this.winstonLogger.info(formattedMessage);
  }

  public error(message: string): void {
    this.ensureInitialized();
    const formattedMessage = `❌  ${message}`;
    this.winstonLogger.error(formattedMessage);
  }

  public step(stepNumber: number, message: string): void {
    this.ensureInitialized();
    const formattedMessage = `🔹 Step ${stepNumber}: ${message}`;
    this.winstonLogger.info(formattedMessage);
  }

  public txHash(hash: string): void {
    this.ensureInitialized();
    const formattedMessage = `🔗 Transaction Hash: ${hash}`;
    this.winstonLogger.info(formattedMessage);
  }

  public address(label: string, address: string): void {
    this.ensureInitialized();
    const formattedMessage = `📍 ${label}: ${address}`;
    this.winstonLogger.info(formattedMessage);
  }
}
// Get the logger instance once
export const logger = Logger.getInstance();