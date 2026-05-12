import { S3Client } from '@aws-sdk/client-s3';
declare const s3Client: S3Client;
declare const BUCKET: string;
export declare function uploadToS3(key: string, body: Buffer, contentType: string): Promise<string>;
export declare function getPresignedUrl(key: string): Promise<string>;
export declare function deleteFromS3(key: string): Promise<void>;
export { s3Client, BUCKET };
//# sourceMappingURL=s3.d.ts.map