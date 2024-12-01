"use client"

import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card"

interface ApiDisplayProps {
  type: "health" | "random"
}

interface HealthResponse {
  status: string
  service: string
}

interface RandomResponse {
  number: number
}

type ApiResponse = HealthResponse | RandomResponse

export function ApiDisplay({ type }: ApiDisplayProps) {
  const [data, setData] = useState<ApiResponse | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)
      try {
        const endpoint = type === "health" ? "/health" : "/random"
        const response = await fetch(`http://127.0.0.1:8000${endpoint}`)
        const result = await response.json()
        setData(result)
      } catch (error) {
        console.error("Error fetching data:", error)
        setData(null)
      }
      setLoading(false)
    }

    fetchData()
    // For random number, refresh every 5 seconds
    let interval: NodeJS.Timeout | null = null
    if (type === "random") {
      interval = setInterval(fetchData, 5000)
    }

    return () => {
      if (interval) clearInterval(interval)
    }
  }, [type])

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Loading...</CardTitle>
        </CardHeader>
      </Card>
    )
  }

  if (!data) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Error</CardTitle>
          <CardDescription>Failed to fetch data from the API</CardDescription>
        </CardHeader>
      </Card>
    )
  }

  if (type === "health") {
    const healthData = data as HealthResponse
    return (
      <Card>
        <CardHeader>
          <CardTitle>Python Backend Health</CardTitle>
          <CardDescription>Current status of the Python backend service</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-2">
            <div className="flex items-center justify-between">
              <span className="font-medium">Status:</span>
              <span className={healthData.status === "healthy" ? "text-green-500" : "text-red-500"}>
                {healthData.status}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="font-medium">Service:</span>
              <span>{healthData.service}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  const randomData = data as RandomResponse
  return (
    <Card>
      <CardHeader>
        <CardTitle>Random Number Generator</CardTitle>
        <CardDescription>Generates a new random number every 5 seconds</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-center">
          <span className="text-4xl font-bold">{randomData.number}</span>
        </div>
      </CardContent>
    </Card>
  )
}
