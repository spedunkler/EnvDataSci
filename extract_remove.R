```{}
don't need this:
poly <- rgdal::readOGR(dsn   = dtaPath,
                       layer = "train_polys",
                       stringsAsFactors = FALSE)


poly@data$id <- as.integer(factor(poly@data$class)) # creates a numeric id useful for rasterization
setDT(poly@data)
# Prepare colors for each class.
cls_dt <- unique(poly@data) %>%   # [raster]
  arrange(id) %>%
  mutate(hex = c(bare        = "#cccccc",
                 forest      = "#006600",
                 hydric      = "#99ffcc",
                 mesic       = "#ffff66",
                 water       = "#003366",
                 willow      = "#66ff33",
                 xeric       = "#ff7f7f"))
view_aoi(color = "#a1d99b") +
  mapView(poly, zcol = "class", col.regions = cls_dt$hex)
poly_utm <- sp::spTransform(poly, CRSobj = rst_lst[[1]]@crs)
```



```#{r extract}
# Create raster template
template_rst <- raster(extent(rst_lst$B02), # B02 has resolution 10 m so appropriate extent
                       resolution = 10,
                       crs = projection(rst_lst$B02))       # [raster]
poly_utm_rst <- rasterize(poly_utm, template_rst, field = 'id')  # [raster]
poly_dt <- as.data.table(rasterToPoints(poly_utm_rst))           # [raster]
setnames(poly_dt, old = "layer", new = "id_cls")                 # [data.table]

points <- SpatialPointsDataFrame(coords = poly_dt[, .(x, y)],    # [sp]
                                 data = poly_dt,
                                 proj4string = poly_utm_rst@crs)

# Extract band values to points
dt <- brick_for_prediction_norm %>%
  extract(y = points) %>%
  as.data.frame %>%
  mutate(id_cls = points@data$id_cls) %>%  # add the class names to each row
  left_join(y = unique(poly@data), by = c("id_cls" = "id")) %>%
  mutate(id_cls = NULL) %>%       # this column is extra now, delete it
  mutate(class = factor(class))

setDT(dt)

```
