"use client";

// import { Button } from "@/components/ui/button"
// import { Textarea } from "@/components/ui/textarea"
// import { useState } from "react"
// import { Card, CardContent } from "@/components/ui/card"
// import { Alert, AlertDescription } from "@/components/ui/alert"
// import { ModeToggle } from "@/components/theme-toggle"
// import { AppSidebar } from "@/components/app-sidebar"
// import {
//   Breadcrumb,
//   BreadcrumbItem,
//   BreadcrumbList,
//   BreadcrumbPage,
// } from "@/components/ui/breadcrumb"
// import { Separator } from "@/components/ui/separator"
// import {
//   SidebarInset,
//   SidebarProvider,
//   SidebarTrigger,
// } from "@/components/ui/sidebar"

// export default function Home() {
//   const [name, setName] = useState("")
//   const [message, setMessage] = useState("")
  
//   const handleWriteMessage = () => {
//     if (name.trim()) {
//       setMessage(`Hello ${name}! Welcome to our application. We're excited to have you here! 🎉`)
//     }
//   }

//   return (
//     <SidebarProvider>
//       <AppSidebar />
//       <SidebarInset>
//         <header className="flex h-16 shrink-0 items-center gap-2 px-4 py-2 transition-[width,height] ease-linear group-has-[[data-collapsible=icon]]/sidebar-wrapper:h-12">
//           <div className="flex items-center gap-2">
//             <SidebarTrigger className="-ml-1" />
//           </div>
//           <div className="pl-4">
//             <h1 className="text-xl font-semibold leading-none tracking-tight">
//               Dashboard
//             </h1>
//             {/* <p className="text-sm text-muted-foreground">
//               Monitor your data and analytics
//               </p> */}
//           </div>
//           <div className="ml-auto flex items-center gap-2">
//             <ModeToggle />
//           </div>
//         </header>
//         {/* // Main content */}
//                   {/* <Separator orientation="vertical" className="mr-2 h-4" />
//             <Breadcrumb>
//               <BreadcrumbList>
//                 <BreadcrumbItem>
//                   <BreadcrumbPage>Home</BreadcrumbPage>
//                 </BreadcrumbItem>
//               </BreadcrumbList>
//             </Breadcrumb> */}
//         <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
//           {/* <Card className="w-full max-w-md mx-auto">
//             <CardContent className="space-y-6 pt-6">
//               <h1 className="text-2xl font-bold text-center">Welcome</h1>
              
//               <div className="space-y-4">
//                 <Textarea
//                   placeholder="Enter your name"
//                   value={name}
//                   onChange={(e) => setName(e.target.value)}
//                   className="min-h-[20px]"
//                 />
                
//                 <Button 
//                   onClick={handleWriteMessage}
//                   className="w-full"
//                 >
//                   Write Message ...
//                 </Button>

//                 {message && (
//                   <Alert className="mt-4">
//                     <AlertDescription>
//                       {message}
//                     </AlertDescription>
//                   </Alert>
//                 )}
//               </div>
//             </CardContent>
//           </Card> */}
//           ABC TEXT
//         </div>
//       </SidebarInset>
//     </SidebarProvider>
//   )
// }

import { AppSidebar } from "@/components/app-sidebar"
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { Separator } from "@/components/ui/separator"
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar"
import SettingsPage from "./(playground)/settings/page";
import { ModeToggle } from "@/components/theme-toggle";

export default function DashboardPage() {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <header className="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-[[data-collapsible=icon]]/sidebar-wrapper:h-12">
          <div className="flex items-center gap-2 px-4">
            <SidebarTrigger className="-ml-1" />
            <Separator orientation="vertical" className="mr-2 h-4" />
            <Breadcrumb>
              <BreadcrumbList>
                <BreadcrumbItem className="hidden md:block">
                  <BreadcrumbLink href="#">
                    Building Your Application
                  </BreadcrumbLink>
                </BreadcrumbItem>
                <BreadcrumbSeparator className="hidden md:block" />
                <BreadcrumbItem>
                  <BreadcrumbPage>Data Fetching</BreadcrumbPage>
                </BreadcrumbItem>
              </BreadcrumbList>
            </Breadcrumb>

            <div className="ml-auto flex items-center gap-2">
             <ModeToggle />
           </div>
           
          </div>
        </header>
        <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
          {/* <div className="grid auto-rows-min gap-4 md:grid-cols-3">
            <div className="aspect-video rounded-xl bg-muted/50" />
            <div className="aspect-video rounded-xl bg-muted/50" />
            <div className="aspect-video rounded-xl bg-muted/50" />
          </div>
          <div className="min-h-[100vh] flex-1 rounded-xl bg-muted/50 md:min-h-min" /> */}
          <SettingsPage />
        </div>
      </SidebarInset>
    </SidebarProvider>
  )
}
