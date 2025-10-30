## ImageRepository - Singleton for centralized image loading and caching
## Handles path resolution across multiple base directories
extends Node

## Cache of loaded textures { full_path: Texture2D }
var texture_cache: Dictionary = {}

## Statistics
var cache_hits: int = 0
var cache_misses: int = 0
var failed_loads: int = 0


## Gets or loads a texture from the repository
## Tries each base directory in order until image is found
## @param base_dirs: List of base directories to search (e.g., ["res://assets/scenes/demo_scene/characters/me/", "res://assets/scenes/common/characters/me/"])
## @param resource_rel_path: Relative path to the image (e.g., "images/front/body/idle.png")
## @return: Texture2D or null if not found
func get_or_load(base_dirs: Array, resource_rel_path: String) -> Texture2D:
	if resource_rel_path == "":
		return null
	
	# Use ResourceRepository to find the actual path
	var full_path = ResourceRepository.get_resource_path(base_dirs, resource_rel_path)
	
	if full_path == "":
		# Not found in any base directory
		failed_loads += 1
		push_warning("Image not found in any base directory: %s (searched: %s)" % [resource_rel_path, str(base_dirs)])
		return null
	
	# Check cache first
	if full_path in texture_cache:
		cache_hits += 1
		return texture_cache[full_path]
	
	# Load from disk
	if ResourceLoader.exists(full_path):
		var texture = load(full_path)
		if texture:
			texture_cache[full_path] = texture
			cache_misses += 1
			return texture
	
	# Failed to load
	failed_loads += 1
	push_warning("Failed to load texture: %s" % full_path)
	return null


## Preloads a texture into cache
func preload_texture(full_path: String) -> bool:
	if full_path in texture_cache:
		return true
	
	if ResourceLoader.exists(full_path):
		var texture = load(full_path)
		if texture:
			texture_cache[full_path] = texture
			return true
	
	return false


## Clears the texture cache
func clear_cache() -> void:
	texture_cache.clear()
	cache_hits = 0
	cache_misses = 0
	failed_loads = 0


## Gets cache statistics
func get_stats() -> Dictionary:
	return {
		"cached_textures": texture_cache.size(),
		"cache_hits": cache_hits,
		"cache_misses": cache_misses,
		"failed_loads": failed_loads
	}


## Prints cache statistics
func print_stats() -> void:
	var stats = get_stats()
	print("=== ImageRepository Stats ===")
	print("Cached textures: %d" % stats.cached_textures)
	print("Cache hits: %d" % stats.cache_hits)
	print("Cache misses: %d" % stats.cache_misses)
	print("Failed loads: %d" % stats.failed_loads)
	print("============================")
