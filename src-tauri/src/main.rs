// Prevent showing console window on Windows
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::process::Command;
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Get the binary name based on the target platform
            #[cfg(target_os = "windows")]
            let binary_name = "python_backend.exe";
            #[cfg(not(target_os = "windows"))]
            let binary_name = "python_backend";

            // Get the resource path from the app's resource directory
            let resource_path = app.path().resource_dir()?.join(binary_name);

            println!("Looking for Python backend at: {:?}", resource_path);

            // Make sure the binary is executable (Unix systems only)
            #[cfg(not(target_os = "windows"))]
            {
                use std::os::unix::fs::PermissionsExt;
                if let Ok(metadata) = std::fs::metadata(&resource_path) {
                    let mut permissions = metadata.permissions();
                    permissions.set_mode(0o755);
                    let _ = std::fs::set_permissions(&resource_path, permissions);
                }
            }

            // Start the Python backend server
            let python_process = Command::new(&resource_path)
                .spawn()
                .expect(&format!("Failed to start Python backend at {:?}", resource_path));

            // Store the process handle to ensure it's kept alive
            app.manage(python_process);

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
