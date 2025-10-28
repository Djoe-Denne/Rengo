## Base class for texture management
## Handles loading, caching, and managing textures
class_name TextureManager
extends RefCounted

## Cache of loaded textures { path: Texture2D }
var texture_cache: Dictionary = {}


## Loads a texture from path with caching
func load_texture(path: String) -> Texture2D:
	# Check cache first
	if path in texture_cache:
		return texture_cache[path]
	
	# Try to load
	if ResourceLoader.exists(path):
		var texture = load(path)
		texture_cache[path] = texture
		return texture
	
	push_warning("Texture not found: %s" % path)
	return null


## Clears the texture cache
func clear_cache() -> void:
	texture_cache.clear()


## Removes a specific texture from cache
func remove_from_cache(path: String) -> void:
	texture_cache.erase(path)

