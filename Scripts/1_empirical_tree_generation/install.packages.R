# Define a vector of package names to check and install
packages_to_install <- c("ape", "ggplot2", "geiger", "ggtree")

# Function to check, install, and load packages
install_and_load <- function(pkg) {
  # Check if the package is installed
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Package", pkg, "not found. Installing..."))
    # Install the package from CRAN
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
  } else {
    message(paste("Package", pkg, "is already installed."))
  }
  
  # Load the package (library function)
  library(pkg, character.only = TRUE)
  message(paste("Package", pkg, "loaded successfully."))
}

# Apply the function to the list of packages
invisible(sapply(packages_to_install, install_and_load))
