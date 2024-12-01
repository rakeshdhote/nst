"use client";

import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { ModeToggle } from "@/components/theme-toggle"

export default function Home() {
  const [name, setName] = useState("")
  const [message, setMessage] = useState("")
  
  const handleWriteMessage = () => {
    if (name.trim()) {
      setMessage(`Hello ${name}! Welcome to our application. We're excited to have you here! 🎉`)
    }
  }

  return (
    <div className="min-h-screen p-8">
      <div className="absolute top-4 right-4">
        <ModeToggle />
      </div>
      <div className="flex flex-col items-center justify-center">
        <Card className="w-full max-w-md">
          <CardContent className="space-y-6 pt-6">
            <h1 className="text-2xl font-bold text-center">Welcome</h1>
            
            <div className="space-y-4">
              <Textarea
                placeholder="Enter your name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="min-h-[20px]"
              />
              
              <Button 
                onClick={handleWriteMessage}
                className="w-full"
              >
                Write Message ...
              </Button>

              {message && (
                <Alert className="mt-4">
                  <AlertDescription>
                    {message}
                  </AlertDescription>
                </Alert>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
