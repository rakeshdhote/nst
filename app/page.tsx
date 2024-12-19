"use client";

import { Button } from "@/components/ui/button";
import { useEffect, useState } from "react";
import { ModeToggle } from "@/components/theme-toggle";
import { AppSidebar } from "@/components/app-sidebar";
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { toast } from "sonner";
import {
  isPermissionGranted,
  requestPermission,
  sendNotification,
} from '@tauri-apps/plugin-notification';
import { ask } from '@tauri-apps/plugin-dialog';
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { Separator } from "@/components/ui/separator"
import SettingsPage from "./(playground)/settings/page";
import { saveWindowState, StateFlags, restoreStateCurrent } from '@tauri-apps/plugin-window-state';
import TreeComponent from "./(playground)/tree/page";

export default function DashboardPage() {
  const [permissionGranted, setPermissionGranted] = useState(false);

  useEffect(() => {
    checkNotificationPermission();
    restoreStateCurrent(StateFlags.ALL);
  }, []);

  const checkNotificationPermission = async () => {
    try {
      let permission = await isPermissionGranted();
      if (!permission) {
        const result = await requestPermission();
        permission = result === 'granted';
      }
      setPermissionGranted(permission);
    } catch (error) {
      console.error('Error checking notification permission:', error);
    }
  };

  const handleNotification = async () => {
    try {
      if (permissionGranted) {
        await sendNotification({ 
          title: 'NST App', 
          body: 'This is a test notification from your NST App!' 
        });
        toast.success('Notification sent successfully!');
      } else {
        toast.error('Notification permission not granted');
        await checkNotificationPermission();
      }
    } catch (error) {
      console.error('Error sending notification:', error);
      toast.error('Failed to send notification');
    }
  };

  const handleConfirmation = async () => {
    const answer = await ask('This action cannot be reverted. Are you sure?', {
      title: 'Tauri',
      kind: 'warning',
    });

    console.log(answer); // Prints boolean to the console
  };

  const handleSaveState = () => {
    try {
      saveWindowState(StateFlags.ALL);
      toast.success('State saved successfully!');
    } catch (error) {
      console.error('Error saving state:', error);
      toast.error('Failed to save state');
    }
  };

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

            <div className="ml-auto flex items-center gap-4">
              <Button 
                variant="outline"
                onClick={handleNotification}
              >
                Send Notification
              </Button>
              <Button 
                variant="outline"
                onClick={handleConfirmation}
              >
                Confirm Action
              </Button>
              <Button 
                variant="outline"
                onClick={handleSaveState}
              >
                Save Window State
              </Button>
              <ModeToggle />
            </div>
          </div>
        </header>
        <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
          <SettingsPage />
        </div>
        <div className="flex flex-1 flex-col gap-4 p-4 pt-0">
          <TreeComponent />
        </div>
      </SidebarInset>
    </SidebarProvider>
  )
}
