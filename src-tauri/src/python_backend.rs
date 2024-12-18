use std::path::{Path, PathBuf};
use std::process::Command;
use tauri::Manager;

pub struct PythonBackend {
    binary_name: String,
}

impl PythonBackend {
    pub fn new(binary_name: &str) -> Self {
        Self {
            binary_name: binary_name.to_string(),
        }
    }

    pub fn get_possible_paths(&self, app: &tauri::App) -> Result<Vec<PathBuf>, String> {
        let app_dir = app
            .path()
            .app_local_data_dir()
            .map_err(|e| format!("Failed to get app directory: {}", e))?;

        let resource_dir = app
            .path()
            .resource_dir()
            .map_err(|e| format!("Failed to get resource directory: {}", e))?;

        Ok(vec![
            resource_dir.join("resources").join(&self.binary_name),
            app_dir.join("resources").join(&self.binary_name),
            PathBuf::from("/usr/lib/tauri2-next-shadcn-python-template/resources")
                .join(&self.binary_name),
        ])
    }

    pub fn find_backend_path(&self, possible_paths: &[PathBuf]) -> Result<PathBuf, std::io::Error> {
        for path in possible_paths {
            println!("Checking path: {:?}", path);
            if path.exists() {
                println!("Found Python backend at: {:?}", path);
                return Ok(path.clone());
            }
        }

        Err(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            "Python backend not found in any of the expected locations",
        ))
    }

    #[cfg(not(target_os = "windows"))]
    pub fn set_executable_permissions(&self, path: &Path) {
        use std::os::unix::fs::PermissionsExt;
        if let Ok(metadata) = std::fs::metadata(path) {
            let mut permissions = metadata.permissions();
            permissions.set_mode(0o755);
            if let Err(e) = std::fs::set_permissions(path, permissions) {
                println!("Warning: Failed to set executable permissions: {}", e);
            }
        }
    }

    #[cfg(target_os = "windows")]
    pub fn set_executable_permissions(&self, _path: &Path) {
        // No need to set executable permissions on Windows
    }

    pub fn start(&self, app: &tauri::App) -> Result<(), String> {
        let possible_paths = self.get_possible_paths(app)?;
        let backend_path = self
            .find_backend_path(&possible_paths)
            .map_err(|e| e.to_string())?;

        self.set_executable_permissions(&backend_path);

        match Command::new(&backend_path).spawn() {
            Ok(python_process) => {
                println!("Python backend started successfully");
                app.manage(python_process);
                Ok(())
            }
            Err(e) => Err(format!("Failed to start Python backend: {}", e)),
        }
    }
}
