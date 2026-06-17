# Visual illustration of a FAIR assessment, using base graphics only (no extra
# package dependencies, so it works in a bare R session and in CRAN examples).

#' @noRd
.fair_cat_colors <- c(F = "#118AB2", A = "#06D6A0", I = "#FFD166", R = "#EF476F")
#' @noRd
.fair_cat_labels <- c(F = "Findable", A = "Accessible", I = "Interoperable",
                      R = "Reusable", FAIR = "Overall FAIR")
#' @noRd
.fair_maturity_labels <- c("incomplete", "initial", "moderate", "advanced")
#' @noRd
.fair_maturity_colors <- c("#fe7d37", "#dfb317", "#97ca00", "#4cc417")

#' @noRd
.lighten <- function(hex, amount = 0.85) {
  rgb <- grDevices::col2rgb(hex)[, 1]
  mixed <- rgb + (255 - rgb) * amount
  grDevices::rgb(mixed[1], mixed[2], mixed[3], maxColorValue = 255)
}

#' @noRd
.maturity_tag <- function(maturity) {
  m <- max(0L, min(3L, as.integer(round(maturity %||% 0))))
  list(label = .fair_maturity_labels[m + 1L], color = .fair_maturity_colors[m + 1L], level = m)
}

#' Plot a FAIR assessment as a scorecard
#'
#' Draws a compact, readable scorecard of a [fair_assessment][fair_assessment]
#' using base graphics (no extra package dependencies). It is the quickest way to
#' *see* an assessment: a horizontal progress bar per FAIR category (or per
#' metric), each annotated with its score and CMMI maturity level. See
#' `vignette("illustrating-fairness")` for worked examples.
#'
#' @param x A `fair_assessment` object returned by [assess_fair()].
#' @param type What to draw. `"category"` (default) draws one bar per FAIR
#'   category (Findable, Accessible, Interoperable, Reusable) plus the overall
#'   score; `"metric"` draws one bar per individual metric, grouped and colored
#'   by category; `"sunburst"` draws a concentric sunburst (an inner ring of the
#'   F/A/I/R categories and an outer ring of the individual metrics, each filled
#'   in proportion to its score) with the overall FAIR percentage in the center.
#' @param colors Named character vector of category fill colors, with names
#'   `"F"`, `"A"`, `"I"`, `"R"`.
#' @param show_maturity Logical; annotate each bar with its maturity level.
#'   Defaults to `TRUE` for `type = "category"`.
#' @param main Title. Defaults to the resolved identifier (or the input id).
#' @param ... Ignored (for S3 method compatibility).
#'
#' @return `x`, invisibly. Called for the side effect of drawing a plot.
#'
#' @examples
#' # A stored example assessment (no network needed):
#' data(fair_example)
#' plot(fair_example)
#' plot(fair_example, type = "metric")
#' plot(fair_example, type = "sunburst")
#' @seealso [assess_fair()], [summary.fair_assessment()], [fair_example]
#' @export
plot.fair_assessment <- function(x, type = c("category", "metric", "sunburst"),
                                 colors = .fair_cat_colors,
                                 show_maturity = (match.arg(type) == "category"),
                                 main = NULL, ...) {
  type <- match.arg(type)
  if (is.null(main)) {
    main <- x$resolved_url %||% x$id %||% "FAIR assessment"
    if (nchar(main) > 64) main <- paste0(substr(main, 1, 61), "...")
  }
  switch(type,
    category = .plot_fair_category(x, colors, show_maturity, main),
    metric = .plot_fair_metric(x, colors, main),
    sunburst = .plot_fair_sunburst(x, colors, main)
  )
  invisible(x)
}

#' @noRd
.fair_short_id <- function(id) {
  parts <- strsplit(id, "-", fixed = TRUE)[[1]]
  if (grepl("^FRSM", id)) parts[3] %||% id else parts[2] %||% id
}

#' @noRd
.sector_poly <- function(rin, rout, a0, a1) {
  ao <- seq(a0, a1, length.out = 48)
  ai <- rev(ao)
  list(x = c(rout * sin(ao * pi / 180), rin * sin(ai * pi / 180)),
       y = c(rout * cos(ao * pi / 180), rin * cos(ai * pi / 180)))
}

#' @noRd
.plot_fair_sunburst <- function(x, colors, main) {
  s <- summary(x)
  df <- as.data.frame(x)
  df <- df[!is.na(df$category) & df$category %in% c("F", "A", "I", "R"), , drop = FALSE]
  if (!nrow(df)) {
    graphics::plot.new(); graphics::text(0.5, 0.5, "No metrics to plot.")
    return(invisible(NULL))
  }
  df$category <- factor(df$category, levels = c("F", "A", "I", "R"))
  df <- df[order(df$category, df$metric_identifier), , drop = FALSE]
  fair <- s[s$category == "FAIR", , drop = FALSE]

  n <- nrow(df)
  step <- 360 / n
  gap <- 1.0  # degrees between slices
  r_in <- c(0.42, 0.64)   # inner: categories
  r_out <- c(0.68, 0.96)  # outer: metrics
  alpha <- function(pct) max(0.18, min(1, (pct %||% 0) / 100))

  op <- graphics::par(mar = c(0.5, 0.5, 2.6, 0.5)); on.exit(graphics::par(op), add = TRUE)
  graphics::plot.new()
  graphics::plot.window(xlim = c(-1.34, 1.34), ylim = c(-1.16, 1.16), asp = 1)

  cursor <- 0
  for (cat in levels(df$category)) {
    idx <- which(df$category == cat)
    if (!length(idx)) next
    a0 <- cursor * step
    a1 <- (cursor + length(idx)) * step
    col <- colors[[cat]] %||% "#94a3b8"
    cpct <- s$percent[s$category == cat]

    # inner category sector
    p <- .sector_poly(r_in[1], r_in[2], a0 + gap / 2, a1 - gap / 2)
    graphics::polygon(p$x, p$y, col = grDevices::adjustcolor(col, alpha.f = alpha(cpct)),
                      border = "white", lwd = 1.4)

    # category label outside
    mid <- (a0 + a1) / 2
    lx <- (r_out[2] + 0.13) * sin(mid * pi / 180)
    ly <- (r_out[2] + 0.13) * cos(mid * pi / 180)
    adj <- if (abs(sin(mid * pi / 180)) < 0.3) 0.5 else if (sin(mid * pi / 180) > 0) 0 else 1
    graphics::text(lx, ly, .fair_cat_labels[[cat]], adj = c(adj, 0.5), cex = 0.78,
                   font = 2, col = "#475569")

    # outer per-metric sectors
    for (k in seq_along(idx)) {
      i <- idx[k]
      m0 <- (cursor + k - 1) * step
      m1 <- (cursor + k) * step
      po <- .sector_poly(r_out[1], r_out[2], m0 + gap / 2, m1 - gap / 2)
      graphics::polygon(po$x, po$y,
                        col = grDevices::adjustcolor(col, alpha.f = alpha(df$percent[i])),
                        border = "white", lwd = 1.2)
      mm <- (m0 + m1) / 2
      rr <- mean(r_out)
      graphics::text(rr * sin(mm * pi / 180), rr * cos(mm * pi / 180),
                     .fair_short_id(df$metric_identifier[i]), cex = 0.6,
                     col = "#1f2937", font = 2)
    }
    cursor <- cursor + length(idx)
  }

  # center score
  fp <- if (nrow(fair)) fair$percent[1] else NA_real_
  graphics::text(0, 0.06, sprintf("%.0f", fp %||% 0), cex = 2.7, font = 2, col = "#0f172a")
  graphics::text(0, -0.16, "% FAIR", cex = 0.75, col = "#94a3b8")
  graphics::title(main = main, cex.main = 1.0, col.main = "#0f172a", line = 1.0)
  invisible(NULL)
}

#' @noRd
.draw_bar <- function(y, frac, color, height = 0.62) {
  frac <- max(0, min(1, frac %||% 0))
  graphics::rect(0, y - height / 2, 1, y + height / 2, col = "#eef2f6",
                 border = NA)
  if (frac > 0) {
    graphics::rect(0, y - height / 2, frac, y + height / 2, col = color,
                   border = NA)
  }
}

#' @noRd
.plot_fair_category <- function(x, colors, show_maturity, main) {
  s <- summary(x)
  cats <- s[s$category %in% c("F", "A", "I", "R"), , drop = FALSE]
  fair <- s[s$category == "FAIR", , drop = FALSE]
  n <- nrow(cats)

  op <- graphics::par(mar = c(2.5, 7.5, 3.2, 1.2), xpd = NA)
  on.exit(graphics::par(op), add = TRUE)

  # categories bottom-to-top R,I,A,F; overall FAIR on a separate row at the top
  ord <- rev(seq_len(n))
  ytop <- n + 1.3
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0.4, ytop + 0.4))

  # gridlines at 0/25/50/75/100%
  for (g in c(0, .25, .5, .75, 1)) {
    graphics::segments(g, 0.5, g, ytop + 0.1, col = "#e2e8f0", lwd = 1)
    graphics::text(g, ytop + 0.35, sprintf("%d%%", round(g * 100)),
                   cex = 0.7, col = "#94a3b8")
  }

  for (i in seq_len(n)) {
    y <- ord[i]
    key <- cats$category[i]
    pct <- cats$percent[i]
    .draw_bar(y, pct / 100, colors[[key]] %||% "#94a3b8")
    graphics::text(-0.02, y, .fair_cat_labels[[key]], adj = c(1, 0.5),
                   cex = 0.95, font = 2, col = "#334155")
    lab <- sprintf("%g/%g  (%s%%)", cats$earned[i], cats$total[i],
                   formatC(pct, format = "f", digits = 0))
    inside <- (pct / 100) > 0.35
    graphics::text(if (inside) (pct / 100) - 0.015 else (pct / 100) + 0.015, y,
                   lab, adj = c(if (inside) 1 else 0, 0.5), cex = 0.78,
                   col = if (inside) "white" else "#475569")
    if (isTRUE(show_maturity)) {
      tg <- .maturity_tag(cats$maturity[i])
      graphics::text(1.005, y, tg$label, adj = c(0, 0.5), cex = 0.7,
                     col = tg$color, font = 2)
    }
  }

  # overall FAIR row
  if (nrow(fair)) {
    y <- ytop
    fp <- fair$percent[1]
    .draw_bar(y, fp / 100, "#073B4C", height = 0.5)
    graphics::text(-0.02, y, .fair_cat_labels[["FAIR"]], adj = c(1, 0.5),
                   cex = 0.95, font = 2, col = "#073B4C")
    graphics::text(0.5, y, sprintf("%g of %g  -  %s%%", fair$earned[1],
                   fair$total[1], formatC(fp, format = "f", digits = 1)),
                   adj = c(0.5, 0.5), cex = 0.82, font = 2, col = "white")
  }

  graphics::title(main = main, cex.main = 1.0, col.main = "#0f172a",
                  line = 1.6, adj = 0)
  graphics::mtext(sprintf("FAIR metrics v%s", x$metric_version %||% "?"),
                  side = 1, line = 1, adj = 1, cex = 0.7, col = "#94a3b8")
  invisible(NULL)
}

#' @noRd
.plot_fair_metric <- function(x, colors, main) {
  df <- as.data.frame(x)
  df <- df[!is.na(df$category) & df$category %in% c("F", "A", "I", "R"), ,
           drop = FALSE]
  # order by FAIR category then identifier
  df$category <- factor(df$category, levels = c("F", "A", "I", "R"))
  df <- df[order(df$category, df$metric_identifier), , drop = FALSE]
  n <- nrow(df)
  if (!n) {
    graphics::plot.new(); graphics::text(0.5, 0.5, "No metrics to plot.")
    return(invisible(NULL))
  }
  pct <- ifelse(is.na(df$percent), 0, df$percent)

  op <- graphics::par(mar = c(2.5, 9, 3.2, 1), xpd = NA)
  on.exit(graphics::par(op), add = TRUE)

  ord <- rev(seq_len(n))
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0.4, n + 0.6))
  for (g in c(0, .25, .5, .75, 1)) {
    graphics::segments(g, 0.5, g, n + 0.4, col = "#e2e8f0", lwd = 1)
    graphics::text(g, n + 0.6, sprintf("%d%%", round(g * 100)), cex = 0.65,
                   col = "#94a3b8")
  }
  for (i in seq_len(n)) {
    y <- ord[i]
    key <- as.character(df$category[i])
    .draw_bar(y, pct[i] / 100, colors[[key]] %||% "#94a3b8", height = 0.66)
    graphics::text(-0.015, y, df$metric_identifier[i], adj = c(1, 0.5),
                   cex = 0.72, font = 2, col = colors[[key]] %||% "#334155")
    inside <- (pct[i] / 100) > 0.18
    graphics::text(if (inside) (pct[i] / 100) - 0.01 else (pct[i] / 100) + 0.01,
                   y, sprintf("%g/%g", df$earned[i], df$total[i]),
                   adj = c(if (inside) 1 else 0, 0.5), cex = 0.66,
                   col = if (inside) "white" else "#475569")
  }
  graphics::title(main = main, cex.main = 1.0, col.main = "#0f172a",
                  line = 1.6, adj = 0)
  # category legend
  lx <- seq(0, 0.75, length.out = 4)
  graphics::mtext(side = 1, line = 1, adj = 0, cex = 0.7, col = "#64748b",
                  text = "F Findable  A Accessible  I Interoperable  R Reusable")
  invisible(NULL)
}
