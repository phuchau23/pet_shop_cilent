#!/bin/bash
# Script to patch isar_flutter_libs build.gradle
ISAR_BUILD_GRADLE="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle"

if [ -f "$ISAR_BUILD_GRADLE" ]; then
    if ! grep -q "namespace = \"dev.isar.isar_flutter_libs\"" "$ISAR_BUILD_GRADLE"; then
        sed -i '/android {/a\    namespace = "dev.isar.isar_flutter_libs"' "$ISAR_BUILD_GRADLE"
        echo "✅ Patched isar_flutter_libs build.gradle"
    else
        echo "✅ Already patched"
    fi
else
    echo "⚠️ isar_flutter_libs build.gradle not found"
fi
