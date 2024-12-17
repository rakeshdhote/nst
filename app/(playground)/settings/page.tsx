'use client';

import { useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "sonner";
import { ChevronRight, ChevronDown, Folder, File } from "lucide-react";

interface FileEntry {
  path: string;
  name: string;
  is_file: boolean;
  size: number;
  children?: FileEntry[];
}

interface FileItemProps {
  entry: FileEntry;
  level: number;
}

const formatFileSize = (bytes: number): string => {
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;
  
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  
  return `${size.toFixed(1)} ${units[unitIndex]}`;
};

function FileItem({ entry, level }: FileItemProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const paddingLeft = `${level * 20}px`;

  const toggleExpand = () => {
    if (!entry.is_file) {
      setIsExpanded(!isExpanded);
    }
  };

  return (
    <div>
      <div 
        className="flex items-center py-1 hover:bg-gray-100 cursor-pointer rounded"
        style={{ paddingLeft }}
        onClick={toggleExpand}
      >
        {!entry.is_file && (
          <span className="mr-1">
            {isExpanded ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
          </span>
        )}
        {entry.is_file ? (
          <File className="h-4 w-4 mr-2" />
        ) : (
          <Folder className="h-4 w-4 mr-2" />
        )}
        <span className="flex-1">{entry.name}</span>
        {entry.is_file && (
          <span className="text-sm text-gray-500 mr-4">{formatFileSize(entry.size)}</span>
        )}
      </div>
      {!entry.is_file && isExpanded && entry.children && (
        <div>
          {entry.children.map((child, index) => (
            <FileItem key={child.path + index} entry={child} level={level + 1} />
          ))}
        </div>
      )}
    </div>
  );
}

export function FileExplorer() {
  const [path, setPath] = useState('');
  const [files, setFiles] = useState<FileEntry[]>([]);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleListFiles = async () => {
    if (!path.trim()) {
      setError('Please enter a valid path');
      return;
    }

    try {
      setError('');
      setIsLoading(true);
      console.log('Listing files for path:', path);
      
      const fileList = await invoke<FileEntry[]>('list_files', { path: path.trim() });
      console.log('Received files:', fileList);
      
      if (Array.isArray(fileList)) {
        setFiles(fileList);
        if (fileList.length === 0) {
          toast.info('Directory is empty');
        } else {
          toast.success(`Found ${fileList.length} items`);
        }
      } else {
        console.error('Unexpected response format:', fileList);
        setError('Received invalid response from server');
        setFiles([]);
      }
    } catch (err) {
      console.error('Error listing files:', err);
      const errorMessage = err instanceof Error ? err.message : 'Failed to list files';
      setError(errorMessage);
      toast.error(errorMessage);
      setFiles([]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSelectFolder = async () => {
    try {
      setError('');
      setIsLoading(true);
      const selectedPath = await invoke<string>('select_folder');
      setPath(selectedPath);
      
      if (selectedPath) {
        console.log('Listing files for path:', selectedPath);
        const fileList = await invoke<FileEntry[]>('list_files', { path: selectedPath.trim() });
        
        if (Array.isArray(fileList)) {
          setFiles(fileList);
          if (fileList.length === 0) {
            toast.info('Directory is empty');
          } else {
            toast.success(`Found ${fileList.length} items`);
          }
        } else {
          console.error('Unexpected response format:', fileList);
          setError('Received invalid response from server');
          setFiles([]);
        }
      }
    } catch (err) {
      console.error('Error:', err);
      const errorMessage = err instanceof Error ? err.message : 'Failed to access folder';
      setError(errorMessage);
      toast.error(errorMessage);
      setFiles([]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle>File Explorer</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex gap-4 mb-4">
          <Input
            type="text"
            placeholder="Enter folder path (e.g., /home/user)"
            value={path}
            onChange={(e) => setPath(e.target.value)}
            className="flex-1"
            onKeyDown={(e) => {
              if (e.key === 'Enter' && path.trim()) {
                handleListFiles();
              }
            }}
          />
          <Button 
            onClick={handleSelectFolder}
            variant="outline"
            disabled={isLoading}
          >
            <Folder className="h-4 w-4 mr-2" />
            {isLoading ? 'Loading...' : 'Select Folder'}
          </Button>
        </div>

        {error && (
          <div className="text-red-500 mb-4 p-2 border border-red-200 rounded bg-red-50">
            {error}
          </div>
        )}

        <div className="text-sm text-muted-foreground mb-4">
          {path ? `Selected path: ${path}` : 'No path selected'}
        </div>

        <div className="border rounded-lg">
          Rust: 
          {files.length > 0 ? (
            <div className="p-2">
              {files.map((entry, index) => (
                <FileItem key={entry.path + index} entry={entry} level={0} />
              ))}
            </div>
          ) : (
            <div className="p-4 text-center text-gray-500">
              {isLoading ? 'Loading...' : 'No files to display'}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export default function SettingsPage() {
  return (
    <div className="flex items-center justify-center h-full">
      <FileExplorer />
    </div>
  )
}
