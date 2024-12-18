// Prevent showing console window on Windows
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod error;
mod files;
mod python_backend;

use python_backend::PythonBackend;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let backend = PythonBackend::new("my_fastapi_app");
            backend.start(app)?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            files::list_files,
            files::select_folder
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
