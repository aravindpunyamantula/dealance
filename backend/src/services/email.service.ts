import nodemailer from 'nodemailer';

class EmailService {
  private transporter: nodemailer.Transporter | null = null;

  private getTransporter() {
    if (this.transporter) return this.transporter;

    const host = process.env.SMTP_HOST || 'smtp.gmail.com';
    const port = parseInt(process.env.SMTP_PORT || '587');
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    // Only create transporter if credentials exist
    if (!user || !pass || user === 'your-email@gmail.com') {
      return null;
    }

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465, // true for 465, false for other ports
      auth: { user, pass },
      // Optimization: use a connection pool to reuse connections
      pool: true,
      maxConnections: 5,
      maxMessages: 100,
      // Timeouts to prevent hanging
      connectionTimeout: 5000, // 5 seconds
      greetingTimeout: 5000,   // 5 seconds
      socketTimeout: 10000,    // 10 seconds
    });

    return this.transporter;
  }

  /**
   * Sends an OTP email. 
   * This is designed to be called without 'await' in the main flow for robustness.
   */
  async sendOtpEmail(email: string, code: string) {
    const transporter = this.getTransporter();
    
    if (!transporter) {
      console.warn(`⚠️  Email service not configured. OTP for ${email} is ${code} (logged for dev)`);
      return;
    }

    // Return a promise that we handle internally
    return transporter.sendMail({
      from: process.env.EMAIL_FROM || '"Dealance" <noreply@dealance.com>',
      to: email,
      subject: 'Your Dealance Verification Code',
      text: `Your Dealance verification code is: ${code}\n\nThis code will expire in 5 minutes.`,
      html: `
        <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; margin: auto; border: 1px solid #eee; border-radius: 10px;">
          <h2 style="color: #EFBA8F;">Dealance Verification</h2>
          <p>Hello,</p>
          <p>Your verification code is:</p>
          <div style="background: #f9f9f9; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
            <h1 style="color: #EFBA8F; letter-spacing: 5px; margin: 0; font-size: 32px;">${code}</h1>
          </div>
          <p>This code will expire in <strong>5 minutes</strong>.</p>
          <p>If you didn't request this code, you can safely ignore this email.</p>
          <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;" />
          <p style="font-size: 12px; color: #888; text-align: center;">&copy; 2026 Dealance. All rights reserved.</p>
        </div>
      `,
    }).then(() => {
      console.log(`✉️  Real email sent successfully to ${email}`);
    }).catch((err) => {
      console.error(`❌ Failed to send email to ${email}:`, err.message);
      // We don't rethrow because this is usually called in background
    });
  }
}

export const emailService = new EmailService();
