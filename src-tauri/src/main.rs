// Prevent showing console window on Windows
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::process::Command;
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Get the binary name based on the target platform
            let binary_name = "fastapi_server";

            // Get the resource path from the app's resource directory
            let app_dir = app.path().app_local_data_dir()
                .map_err(|e| format!("Failed to get app directory: {}", e))?;

            let possible_paths: Vec<std::path::PathBuf> = vec![
                app.path()
                    .resource_dir()
                    .map_err(|e| format!("Failed to get resource directory: {}", e))?
                    .join("resources")
                    .join(binary_name),
                app_dir.join("resources").join(binary_name),
                std::path::PathBuf::from("/usr/lib/tauri2-next-shadcn-python-template/resources").join(binary_name),
            ];

            println!("Looking for Python backend in the following locations:");
            for path in &possible_paths {
                println!("- {:?}", path);
            }

            let backend_path = possible_paths.iter()
                .find(|path| path.exists())
                .ok_or_else(|| {
                    std::io::Error::new(
                        std::io::ErrorKind::NotFound,
                        "Python backend not found in any of the expected locations"
                    )
                })?;

            println!("Found Python backend at: {:?}", backend_path);

            // Make sure the binary is executable (Unix systems only)
            #[cfg(not(target_os = "windows"))]
            {
                use std::os::unix::fs::PermissionsExt;
                if let Ok(metadata) = std::fs::metadata(&backend_path) {
                    let mut permissions = metadata.permissions();
                    permissions.set_mode(0o755);
                    if let Err(e) = std::fs::set_permissions(&backend_path, permissions) {
                        println!("Warning: Failed to set executable permissions: {}", e);
                    }
                }
            }

            // Start the Python backend server
            match Command::new(&backend_path).spawn() {
                Ok(python_process) => {
                    println!("Python backend started successfully");
                    // Store the process handle to ensure it's kept alive
                    app.manage(python_process);
                    Ok(())
                }
                Err(e) => {
                    Err(format!("Failed to start Python backend: {}", e).into())
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
