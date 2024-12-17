use std::fmt;

#[derive(Debug)]
pub enum AppError {
    IoError(std::io::Error),
    BackendError(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::IoError(err) => write!(f, "IO Error: {}", err),
            AppError::BackendError(err) => write!(f, "Backend Error: {}", err),
        }
    }
}

impl std::error::Error for AppError {}

impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::IoError(err)
    }
}

impl From<String> for AppError {
    fn from(err: String) -> Self {
        AppError::BackendError(err)
    }
}
