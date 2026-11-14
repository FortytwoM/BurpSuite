#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Building loader.jar..."

ASM_VERSION="9.5"
ASM_DIR="$PROJECT_ROOT/lib"
ASM_JAR="$ASM_DIR/asm-$ASM_VERSION.jar"
ASM_TREE_JAR="$ASM_DIR/asm-tree-$ASM_VERSION.jar"

# jar может отсутствовать в PATH (например, в git bash доступны только шимы java/javac)
JAR_TOOL="$(command -v jar || true)"
if [ -z "$JAR_TOOL" ]; then
    JAVA_HOME_DIR="$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^ *java.home = //p' | tr -d '\r')"
    if command -v cygpath >/dev/null 2>&1; then
        JAVA_HOME_DIR="$(cygpath -u "$JAVA_HOME_DIR")"
    fi
    for candidate in "$JAVA_HOME_DIR/bin/jar" "$JAVA_HOME_DIR/bin/jar.exe"; do
        if [ -x "$candidate" ]; then
            JAR_TOOL="$candidate"
            break
        fi
    done
fi
if [ -z "$JAR_TOOL" ]; then
    echo "Error: jar tool not found. Please install a JDK (not just a JRE)."
    exit 1
fi

download() {
    local dest="$1"
    shift
    local url
    for url in "$@"; do
        echo "Trying: $url"
        if command -v wget >/dev/null 2>&1; then
            wget -q "$url" -O "$dest.tmp" && mv "$dest.tmp" "$dest" && return 0
        elif command -v curl >/dev/null 2>&1; then
            curl -sLf "$url" -o "$dest.tmp" && mv "$dest.tmp" "$dest" && return 0
        fi
        rm -f "$dest.tmp"
    done
    return 1
}

if [ ! -f "$ASM_JAR" ] || [ ! -f "$ASM_TREE_JAR" ]; then
    echo "Downloading ASM library..."
    mkdir -p "$ASM_DIR"

    download "$ASM_JAR" \
        "https://repo1.maven.org/maven2/org/ow2/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar" \
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar" \
        || { echo "Error: Failed to download ASM library from all URLs"; exit 1; }

    download "$ASM_TREE_JAR" \
        "https://repo1.maven.org/maven2/org/ow2/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar" \
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar" \
        || { echo "Error: Failed to download ASM-tree library from all URLs"; exit 1; }

    echo "ASM library downloaded successfully"
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

MANIFEST="$TEMP_DIR/MANIFEST.MF"
cat > "$MANIFEST" <<'EOF'
Manifest-Version: 1.0
Can-Retransform-Classes: true
Main-Class: Keygen
Premain-Class: Loader

EOF

echo "Compiling Java classes..."
cd src
javac --release 21 -cp "$ASM_JAR:$ASM_TREE_JAR" Loader.java Filter.java Keygen.java

echo "Creating JAR file..."
"$JAR_TOOL" cfm "$PROJECT_ROOT/loader.jar" "$MANIFEST" Loader.class Filter.class Keygen.class

echo "Cleaning up compiled classes..."
rm -f Loader.class Filter.class Keygen.class
cd "$PROJECT_ROOT"

echo "Adding ASM libraries to JAR..."
mkdir -p "$TEMP_DIR/asm" "$TEMP_DIR/asm-tree"
(cd "$TEMP_DIR/asm" && "$JAR_TOOL" xf "$ASM_JAR")
(cd "$TEMP_DIR/asm-tree" && "$JAR_TOOL" xf "$ASM_TREE_JAR")

"$JAR_TOOL" uf loader.jar -C "$TEMP_DIR/asm" .
"$JAR_TOOL" uf loader.jar -C "$TEMP_DIR/asm-tree" .

echo "Restoring manifest..."
"$JAR_TOOL" ufm loader.jar "$MANIFEST"

echo "Verifying final JAR..."
for entry in META-INF/MANIFEST.MF Loader.class Filter.class Keygen.class; do
    if ! "$JAR_TOOL" tf loader.jar | grep -qx "$entry"; then
        echo "ERROR: $entry missing in final JAR!"
        exit 1
    fi
done
echo "Final JAR verified successfully"

echo "Done! loader.jar created successfully."
echo "Contents:"
"$JAR_TOOL" tf loader.jar
