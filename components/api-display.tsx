"use client"

import { useEffect, useState, useRef } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card"
import { toast } from "sonner"

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
  const isFirstMount = useRef(true)
  const previousNumber = useRef<number | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)
      try {
        const endpoint = type === "health" ? "/health" : "/random"
        const response = await fetch(`http://127.0.0.1:8000${endpoint}`)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        const result = await response.json()
        setData(result)
        
        // Show success toast only on first mount for health check
        if (type === "health" && isFirstMount.current) {
          toast.success(`Backend service is ${result.status}`)
          isFirstMount.current = false
        }
        // For random numbers, only show toast if number changes
        else if (type === "random" && result.number !== previousNumber.current) {
          previousNumber.current = result.number
          if (isFirstMount.current) {
            toast.success(`Random number: ${result.number}`)
            isFirstMount.current = false
          }
        }
      } catch (error) {
        console.error("Error fetching data:", error)
        setData(null)
        toast.error(`Failed to fetch ${type} data`, {
          description: error instanceof Error ? error.message : "Unknown error occurred",
        })
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
      // Reset first mount flag when component unmounts
      isFirstMount.current = true
      previousNumber.current = null
    }
  }, [type])

  if (loading && !data) {
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
        <CardTitle>Random Number</CardTitle>
        <CardDescription>Generated random number from the Python backend</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold text-center">{randomData.number}</div>
      </CardContent>
    </Card>
  )
}
