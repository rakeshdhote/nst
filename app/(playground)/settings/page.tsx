'use client';

import { useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "sonner";
import { ChevronRight, ChevronDown, Folder, File } from "lucide-react";
import config from '@/config.json';

// FileEntry represents a single file or folder
interface FileEntry {
  path: string; // full path of the file or folder
  name: string; // name of the file or folder (without path)
  is_file: boolean; // true if the entry is a file, false if it's a folder
  size: number; // size of the file (0 if it's a folder)
  children?: FileEntry[]; // children of the folder (if any)
}

// FileItemProps represents the props passed to the FileItem component
interface FileItemProps {
  entry: FileEntry;
  level: number; // level of indentation for the item
}

// formatFileSize formats a file size in bytes to a human-readable string
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

// FileItem renders a single file or folder
function FileItem({ entry, level }: FileItemProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const paddingLeft = `${level * 20}px`; // indentation for the item

  // toggleExpand toggles the expansion of the folder
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

// FileExplorer renders the file explorer component
function FileExplorer() {
  const [path, setPath] = useState('');
  const [files, setFiles] = useState<FileEntry[]>([]);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [extensions, setExtensions] = useState<string[]>([]); // Add this line to setFiles
  const [apiResponse, setApiResponse] = useState<string>(''); // State to hold API response

  // handleListFiles lists the files in the given folder
  const handleListFiles = async () => {
    if (!path.trim()) {
      return;
    }
    setIsLoading(true);
    try {
      const response = await fetch(`http://${config.python_server.host}:${config.python_server.port}/explorefolder`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ folder: path.trim() })
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      const prettyData = JSON.stringify(data, null, 2);
      console.log(prettyData);
      const fileEntries = data.files.map((filePath: string) => ({
        path: filePath,
        name: filePath.split('/').pop() || '',
        is_file: true,
        size: 0,
      }));
      setFiles(fileEntries);
      setExtensions(data.extensions);
    } catch (err) {
      console.error(err);
      setError('Failed to list files');
    } finally {
      setIsLoading(false);
    }
  };

  const handleApiCall = async () => {
    try {
      const response = await fetch(`http://${config.python_server.host}:${config.python_server.port}/explorefolder`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ folder: path.trim() })
      });

      console.log('Response status:', response.status); // Log the response status
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Error response:', errorText);
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const text = await response.text(); // Get raw response as text
      console.log('Raw response:', text); // Log the raw response
      const data = JSON.parse(text); // Parse the text as JSON
      const prettyData = JSON.stringify(data, null, 2);
      setApiResponse(prettyData); // Update state with the pretty-printed response
    } catch (error) {
      console.error('Error fetching files:', error);
    }
  };

  // handleSelectFolder opens the folder selection dialog
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
    <Card className="w-full max-w-7xl mx-auto p-4 bg-background shadow-lg">
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
            // variant="outline"
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

        {/* <Button 
          onClick={handleListFiles}
          disabled={isLoading}
        >
          {isLoading ? 'Loading...' : 'List Files'}
        </Button> */}

        <Button 
          onClick={handleApiCall}
        >
          Make API Call
        </Button>

        {apiResponse && (
          <div className="text-sm text-muted-foreground mb-4">
            API Response: <pre>{apiResponse}</pre>
          </div>
        )}

        {extensions.length > 0 && (
          <div className="text-sm text-muted-foreground mb-4">
            Found extensions: {extensions.join(', ')}
          </div>
        )}

        {/* <div className="border rounded-lg">
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
        </div> */}
      </CardContent>
    </Card>
  );
}

export default function SettingsPage() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Settings</h1>
      <FileExplorer />
    </div>
  );
}
