use serde::Serialize;
use std::fs;
use std::path::Path;
use log::{info, error};
use native_dialog::FileDialog;

#[derive(Serialize, Debug)]
pub struct FileEntry {
    path: String,
    name: String,
    is_file: bool,
    size: u64,
    children: Option<Vec<FileEntry>>,
}

#[tauri::command]
pub fn list_files(path: &str) -> Result<Vec<FileEntry>, String> {
    info!("Listing files for path: {}", path);
    list_directory_contents(Path::new(path))
}

#[tauri::command]
pub fn select_folder() -> Result<String, String> {
    match FileDialog::new()
        .set_location("~")
        .show_open_single_dir() {
        Ok(Some(path)) => Ok(path.to_string_lossy().into_owned()),
        Ok(None) => Err("No folder selected".to_string()),
        Err(e) => Err(format!("Error selecting folder: {}", e)),
    }
}

fn list_directory_contents(dir_path: &Path) -> Result<Vec<FileEntry>, String> {
    let entries = match fs::read_dir(dir_path) {
        Ok(entries) => entries,
        Err(e) => {
            error!("Failed to read directory {:?}: {}", dir_path, e);
            return Err(e.to_string());
        }
    };

    let mut files = Vec::new();
    
    for entry_result in entries {
        match entry_result {
            Ok(entry) => {
                match entry.metadata() {
                    Ok(metadata) => {
                        let path = entry.path();
                        let name = path.file_name()
                            .map(|n| n.to_string_lossy().into_owned())
                            .unwrap_or_default();
                        
                        let children = if metadata.is_dir() {
                            match list_directory_contents(&path) {
                                Ok(child_entries) => Some(child_entries),
                                Err(_) => Some(vec![]) // Empty vec for unreadable directories
                            }
                        } else {
                            None
                        };

                        let file_entry = FileEntry {
                            path: path.to_string_lossy().into_owned(),
                            name,
                            is_file: metadata.is_file(),
                            size: metadata.len(),
                            children,
                        };
                        info!("Found file entry: {:?}", file_entry);
                        files.push(file_entry);
                    }
                    Err(e) => {
                        error!("Failed to get metadata for {:?}: {}", entry.path(), e);
                    }
                }
            }
            Err(e) => {
                error!("Failed to read directory entry: {}", e);
            }
        }
    }
    
    // Sort entries: directories first, then files, both alphabetically
    files.sort_by(|a, b| {
        match (a.is_file, b.is_file) {
            (true, false) => std::cmp::Ordering::Greater,
            (false, true) => std::cmp::Ordering::Less,
            _ => a.name.to_lowercase().cmp(&b.name.to_lowercase()),
        }
    });

    info!("Found {} files/directories", files.len());
    Ok(files)
}
