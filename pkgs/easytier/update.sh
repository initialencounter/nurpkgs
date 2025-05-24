version=$(curl "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" | jq -r '.tag_name')

echo "EasyTier latest version: $version"

amd64_url="https://github.com/EasyTier/EasyTier/releases/download/${version}/easytier-linux-x86_64-${version}.zip"
arm64_url="https://github.com/EasyTier/EasyTier/releases/download/${version}/easytier-linux-aarch64-${version}.zip"

# use friendlier hashes
amd64_hash=$(nix-prefetch-url $amd64_url)
arm64_hash=$(nix-prefetch-url $arm64_url)
amd64_hash=$(nix hash to-sri --type sha256 "$amd64_hash")
arm64_hash=$(nix hash to-sri --type sha256 "$arm64_hash")

sed -i "s|# Last updated: .*\.|# Last updated: $(date +%F)\.|g" ./sources.nix
sed -i "s|easytier_version = \".*\";|easytier_version = \"$version\";|g" ./sources.nix
sed -i "s|easytier_amd64_url = \".*\";|easytier_amd64_url = \"$amd64_url\";|g" ./sources.nix
sed -i "s|easytier_amd64_hash = \".*\";|easytier_amd64_hash = \"$amd64_hash\";|g" ./sources.nix
sed -i "s|easytier_arm64_url = \".*\";|easytier_arm64_url = \"$arm64_url\";|g" ./sources.nix
sed -i "s|easytier_arm64_hash = \".*\";|easytier_arm64_hash = \"$arm64_hash\";|g" ./sources.nix