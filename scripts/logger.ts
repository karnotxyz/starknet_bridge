import chalk from 'chalk';

export class Logger {
  static success(message: string): void {
    console.log(chalk.green(`✅  ${message}`));
  }

  static info(message: string): void {
    console.log(chalk.blue(`ℹ️  ${message}`));
  }

  static error(message: string): void {
    console.log(chalk.red(`❌  ${message}`));
  }

  static step(stepNumber: number, message: string): void {
    console.log(chalk.magenta(`[${stepNumber}] ${message}`));
  }

  static txHash(hash: string): void {
    console.log(`Transaction hash: ${chalk.cyan(hash)}`);
  }

  static address(label: string, address: string): void {
    console.log(`🏡  ${label}: ${chalk.green(address)}`);
  }
}
