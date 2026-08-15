import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Codex Seoul Sprint Kit",
  description: "하루 만에 아이디어를 실제 제품으로 만드는 해커톤 스타터"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
