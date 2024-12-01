"use client"

import { ApiDisplay } from "@/components/api-display"
import { usePathname } from "next/navigation"

export default function PlaygroundLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const pathname = usePathname()

  // Determine which API display to show based on the pathname
  const getApiDisplay = () => {
    if (pathname === "/history") {
      return <ApiDisplay type="health" />
    }
    if (pathname === "/starred") {
      return <ApiDisplay type="random" />
    }
    return children
  }

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      {getApiDisplay()}
    </div>
  )
}
