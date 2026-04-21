mkdatasetfiles <- function(n_files,
                           dir,
                           size_mb,
                           prefix = "file_",
                           dataset = datasets::ChickWeight,
                           extra_cols = 10L,
                           max_int = 1000L,
                           chunk_size_mb = 8,
                           chunk_rows = NULL,
                           show_progress = TRUE) {
  stopifnot(
    length(n_files) == 1L, is.numeric(n_files), n_files >= 1, n_files == as.integer(n_files),
    length(dir) == 1L, nzchar(dir),
    length(size_mb) == 1L, is.numeric(size_mb), size_mb > 0,
    length(prefix) == 1L, nzchar(prefix),
    is.data.frame(dataset),
    length(extra_cols) == 1L, extra_cols >= 0, extra_cols == as.integer(extra_cols),
    length(max_int) == 1L, max_int >= 1, max_int == as.integer(max_int),
    length(chunk_size_mb) == 1L, is.numeric(chunk_size_mb), chunk_size_mb > 0,
    is.null(chunk_rows) ||
      (length(chunk_rows) == 1L && chunk_rows >= 1 && chunk_rows == as.integer(chunk_rows)),
    is.logical(show_progress), length(show_progress) == 1L
  )

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  target_bytes <- as.numeric(size_mb) * 1024^2
  chunk_target_bytes <- min(as.numeric(chunk_size_mb) * 1024^2, target_bytes)
  width <- max(1L, nchar(as.character(n_files)))

  dataset[] <- lapply(dataset, as.character)
  n_base <- nrow(dataset)
  if (n_base == 0L) stop("`dataset` must have at least one row.")

  base_names <- names(dataset)
  extra_names <- if (extra_cols > 0L) paste0("rand", seq_len(extra_cols)) else character(0)
  header_raw <- charToRaw(paste0(paste(c(base_names, extra_names), collapse = ","), "\n"))
  base_row_lines <- do.call(paste, c(dataset, list(sep = ",")))
  rand_lut <- if (extra_cols > 0L) as.character(0:(max_int - 1L)) else NULL
  out_files <- character(n_files)

  make_chunk_lines <- if (extra_cols > 0L) {
    function(start_row, n_rows) {
      idx <- ((seq.int(start_row, length.out = n_rows) - 1L) %% n_base) + 1L
      rand_chr <- matrix(
        rand_lut[sample.int(max_int, n_rows * extra_cols, replace = TRUE)],
        nrow = n_rows,
        ncol = extra_cols
      )
      rand_lines <- do.call(
        paste,
        c(as.data.frame(rand_chr, stringsAsFactors = FALSE), list(sep = ","))
      )
      paste0(base_row_lines[idx], ",", rand_lines)
    }
  } else {
    function(start_row, n_rows) {
      idx <- ((seq.int(start_row, length.out = n_rows) - 1L) %% n_base) + 1L
      base_row_lines[idx]
    }
  }

  chunk_rows <- if (is.null(chunk_rows)) {
    sample_n <- min(n_base, 1000L)
    sample_lines <- make_chunk_lines(1L, sample_n)
    sample_bytes <- as.numeric(utils::object.size(sample_lines))
    bytes_per_row <- max(1, ceiling(sample_bytes / sample_n))
    max(1L, as.integer(floor(chunk_target_bytes / bytes_per_row)))
  } else {
    as.integer(chunk_rows)
  }

  pb <- NULL
  if (show_progress) {
    pb <- utils::txtProgressBar(min = 0L, max = n_files, style = 3)
    on.exit(if (!is.null(pb)) close(pb), add = TRUE)
  }

  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  saved_seed <- if (had_seed) get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    if (had_seed) {
      assign(".Random.seed", saved_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)

  for (i in seq_len(n_files)) {
    set.seed(i)

    out_path <- file.path(dir, sprintf("%s%0*d.csv", prefix, width, i))
    out_files[i] <- out_path

    file_con <- file(out_path, open = "wb")
    on.exit(close(file_con), add = TRUE)

    writeBin(header_raw, file_con)
    bytes_written <- length(header_raw)
    start_row <- 1L

    repeat {
      remaining_bytes <- target_bytes - bytes_written
      if (remaining_bytes <= 0L) break

      lines <- make_chunk_lines(start_row, chunk_rows)
      line_bytes <- nchar(lines, type = "bytes") + 1L
      keep_n <- findInterval(remaining_bytes, cumsum(line_bytes))
      if (keep_n == 0L) break

      if (keep_n < length(lines)) {
        lines <- lines[seq_len(keep_n)]
        line_bytes <- line_bytes[seq_len(keep_n)]
      }

      writeChar(paste(lines, collapse = "\n"), file_con, eos = NULL, useBytes = TRUE)
      writeBin(as.raw(10L), file_con)

      bytes_written <- bytes_written + sum(line_bytes)
      start_row <- ((start_row + length(lines) - 1L) %% n_base) + 1L

      if (length(lines) < chunk_rows) break
    }

    close(file_con)
    on.exit(NULL, add = FALSE)

    if (show_progress) utils::setTxtProgressBar(pb, i)
  }

  invisible(file.path(normalizePath(dir, winslash = "/", mustWork = FALSE), basename(out_files)))
}
