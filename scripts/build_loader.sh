#!/bin/bash

echo "Building loader.jar..."

ASM_VERSION="9.5"
ASM_DIR="./lib"
ASM_JAR="$ASM_DIR/asm-$ASM_VERSION.jar"
ASM_TREE_JAR="$ASM_DIR/asm-tree-$ASM_VERSION.jar"

if [ ! -f "$ASM_JAR" ]; then
    echo "Downloading ASM library..."
    mkdir -p "$ASM_DIR"
    ASM_URLS=(
        "https://repo1.maven.org/maven2/org/ow2/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar"
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar"
    )
    ASM_TREE_URLS=(
        "https://repo1.maven.org/maven2/org/ow2/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar"
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar"
    )
    
    downloaded=false
    for url in "${ASM_URLS[@]}"; do
        if command -v wget &> /dev/null; then
            if wget -q "$url" -O "$ASM_JAR" 2>/dev/null; then
                downloaded=true
                break
            fi
        elif command -v curl &> /dev/null; then
            if curl -sL "$url" -o "$ASM_JAR" 2>/dev/null; then
                downloaded=true
                break
            fi
        fi
    done
    
    if [ "$downloaded" = false ]; then
        echo "Error: Failed to download ASM library from all URLs"
        exit 1
    fi
    
    downloaded=false
    for url in "${ASM_TREE_URLS[@]}"; do
        if command -v wget &> /dev/null; then
            if wget -q "$url" -O "$ASM_TREE_JAR" 2>/dev/null; then
                downloaded=true
                break
            fi
        elif command -v curl &> /dev/null; then
            if curl -sL "$url" -o "$ASM_TREE_JAR" 2>/dev/null; then
                downloaded=true
                break
            fi
        fi
    done
    
    if [ "$downloaded" = false ]; then
        echo "Error: Failed to download ASM-tree library from all URLs"
        exit 1
    fi
    
    echo "ASM library downloaded successfully"
fi

cd src

echo "Compiling Java classes..."
javac --release 21 -cp "../$ASM_JAR:../$ASM_TREE_JAR" Loader.java Filter.java Keygen.java

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Creating JAR file..."
jar cfm ../loader.jar ../META-INF/MANIFEST.MF Loader.class Filter.class Keygen.class

echo "Cleaning up compiled classes..."
rm -f Loader.class Filter.class Keygen.class

cd ..

echo "Adding ASM libraries to JAR..."
TEMP_DIR=$(mktemp -d)

echo "Extracting current manifest..."
jar xf loader.jar META-INF/MANIFEST.MF 2>/dev/null
MANIFEST_BACKUP="$TEMP_DIR/MANIFEST.MF"
if [ -f "META-INF/MANIFEST.MF" ]; then
    cp "META-INF/MANIFEST.MF" "$MANIFEST_BACKUP"
    echo "Manifest backed up"
fi

echo "Extracting ASM libraries..."
unzip -q "$ASM_JAR" -d "$TEMP_DIR/asm" 2>/dev/null
unzip -q "$ASM_TREE_JAR" -d "$TEMP_DIR/asm-tree" 2>/dev/null

echo "Adding ASM classes to JAR..."
jar uf loader.jar -C "$TEMP_DIR/asm" . 2>/dev/null
jar uf loader.jar -C "$TEMP_DIR/asm-tree" . 2>/dev/null

echo "Restoring manifest..."
if [ -f "$MANIFEST_BACKUP" ]; then
    mkdir -p META-INF
    cp "$MANIFEST_BACKUP" "META-INF/MANIFEST.MF"
    jar ufm loader.jar "META-INF/MANIFEST.MF" 2>/dev/null
    rm -rf META-INF
    echo "Manifest restored"
else
    echo "WARNING: Manifest backup not found, using original"
    jar ufm loader.jar "../META-INF/MANIFEST.MF" 2>/dev/null
fi

rm -rf "$TEMP_DIR"

echo "Verifying final JAR..."
if ! jar tf loader.jar 2>/dev/null | grep -q "META-INF/MANIFEST.MF"; then
    echo "ERROR: MANIFEST.MF missing in final JAR!"
    exit 1
fi
echo "Final JAR verified successfully"

if [ $? -ne 0 ]; then
    echo "JAR creation failed!"
    exit 1
fi

echo "Done! loader.jar created successfully."
echo "Contents:"
jar tf loader.jar

