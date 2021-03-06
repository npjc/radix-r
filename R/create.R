


#' Create a Radix website
#'
#' Create a basic skeleton for a Radix website or blog. Use the `create_website()`
#' function for a website and the `create_blog()` function for a blog.
#'
#' @param dir Directory for website
#' @param title Title of website
#' @param gh_pages Configure the site for publishing using [GitHub
#'   Pages](https://pages.github.com/)
#' @param edit Open site index file or welcome post in an editor.
#'
#' @note The `dir` and `title` parameters are required (they will be prompted for
#'   interatively if they are not specified).
#'
#' @export
create_website <- function(dir, title, gh_pages = FALSE, edit = interactive()) {
  do_create_website(dir, title, gh_pages, edit, "website")
  render_website(dir, "website")
  invisible(NULL)
}


#' @rdname create_website
#' @export
create_blog <- function(dir, title, gh_pages = FALSE, edit = interactive()) {

  # create the website
  params <- do_create_website(dir, title, gh_pages, edit = FALSE, "blog")

  # create the welcome post
  welcome <- "welcome.Rmd"
  target_path <- file.path(params$dir, "_posts", "welcome")
  render_template(
    file = welcome,
    type = "blog",
    target_path = target_path,
    data = list(
      title = params$title,
      date = format(Sys.Date(), "%m-%d-%Y")
    )
  )

  # render the site
  render_website(dir, "blog")

  # edit the welcome post if requested
  if (edit)
    edit_file(file.path(target_path, welcome))

  invisible(NULL)
}


#' Create a new blog post
#'
#' @param title Post title
#' @param author Post author. Automatically drawn from previous post if not provided.
#' @param slug Post slug (directory name). Automatically computed from title if not
#'   provided.
#' @param date_prefix Data prefix for post slug (preserves chronological order for posts
#'   within the filesystem).
#' @param draft Mark the post as a `draft` (don't include it in the article listing).
#' @param edit Open the post in an editor after creating it.
#'
#' @note This function must be called from with a working directory that is within
#'  a Radix website.
#'
#' @export
create_post <- function(title, author = "auto", slug = "auto", date_prefix = TRUE,
                        draft = FALSE, edit = interactive()) {

  # determine site_dir (must call from within a site)
  site_dir <- find_site_dir(".")
  if (is.null(site_dir))
    stop("You must call create_post from within a Radix website")

  # auto-slug
  if (identical(slug, "auto")) {
    slug <- tolower(title)
    slug <- gsub("\\s+", "-", slug)              # replace spaces with -
    slug <- gsub("[^a-zA-Z0-9\\-]+", "", slug)   # remove all non-word chars
    slug <- gsub("\\-{2,}", "-", slug)           # replace multiple - with single -
    slug <- gsub("^-+", "", slug)                # trim - from start of text
    slug <- gsub("-+$", "", slug)                # trim - from end of text
  } else {
    slug <- gsub("\\s+", "-", title)             # replace spaces with -
  }

  # add date prefix
  if (!identical(date_prefix, FALSE)) {
    if (isTRUE(date_prefix))
      date_prefix <- Sys.Date()
    else if (is.character(date_prefix))
      date_prefix <- parse_date(date_prefix)
    if (lubridate::is.Date(date_prefix) ||
        lubridate::is.POSIXct(date_prefix) ||
        lubridate::is.POSIXlt(date_prefix))
      date_prefix <- as.character(date_prefix, format = "%Y-%m-%d")
    else
      stop("You must specify either TRUE/FALSE or a date for date_prefix")
    slug <- paste(date_prefix, slug, sep = "-")
  }

  # determine author
  if (identical(author, "auto")) {

    # look for previous posts
    site_config <- site_config(site_dir)
    posts_index <- file.path(site_dir, site_config$output_dir, "posts", "posts.json")
    if (file.exists(posts_index))
      posts <- jsonlite::read_json(posts_index)
    else
      posts <- list()


  }

  slug

}


# ---
# title: "The Sharpe Ratio"
# description: |
#   In this post we present a classic finance use case using the
# PerformanceAnalytics, quantmod, and dygraphs packages.
# We'll demonstrate importing stock data, building a portfolio,
#   and then calculating the Sharpe Ratio.
# author:
#   - name: "Jonathan Regenstein"
#     url: https://www.linkedin.com/in/jkregenstein/
#     affiliation: RStudio
#     affiliation_url: https://www.rstudio.com
# date: 11-09-2016
# output:
#   radix::radix_article:
#     self_contained: false
# ---





new_project_create_website <- function(dir, ...) {
  params <- list(...)
  create_website(dir, params$title, params$gh_pages, edit = FALSE)
}

new_project_create_blog <- function(dir, ...) {
  params <- list(...)
  create_blog(dir, params$title, params$gh_pages, edit = FALSE)
}

do_create_website <- function(dir, title, gh_pages, edit, type) {

  # prompt for argumets if we need to
  if (missing(dir)) {
    if (interactive())
      dir <- readline(sprintf("Enter directory name for %s: ", type))
    else
      stop("dir argument must be specified", call. = FALSE)
  }
  if (missing(title)) {
    if (interactive())
      title <- readline(sprintf("Enter a title for the %s: ", type))
    else
      stop("title argument must be specified", call. = FALSE)
  }

  # ensure dir exists
  message("Creating website directory ", dir)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  # copy template files
  render_website_template <- function(file, data = list()) {
    render_template(file, type, dir, data)
  }
  render_website_template("_site.yml", data = list(
    name = basename(dir),
    title = title,
    output_dir = if (gh_pages) "docs" else "_site"
  ))
  render_website_template("index.Rmd", data = list(title = title, gh_pages = gh_pages))
  render_website_template("about.Rmd")

  # if this is for gh-pages then create .nojekyll
  if (gh_pages) {
    nojekyll <- file.path(dir, ".nojekyll")
    message("Creating ", nojekyll, " for gh-pages")
    file.create(nojekyll)
  }

  if (edit)
    edit_file(file.path(dir, "index.Rmd"))

  invisible(list(
    dir = dir,
    title = title
  ))
}


render_website <- function(dir, type) {
  message(sprintf("Rendering %s...", type))
  rmarkdown::render_site(dir)
}

render_template <- function(file, type, target_path, data = list()) {
  message("Creating ", file.path(target_path, file))
  template <- system.file(file.path("rstudio", "templates", "project", type, file),
                          package = "radix")
  template <- paste(readLines(template, encoding = "UTF-8"), collapse = "\n")
  output <- whisker::whisker.render(template, data)
  if (!dir_exists(target_path))
    dir.create(target_path, recursive = TRUE, showWarnings = FALSE)
  writeLines(output, file.path(target_path, file), useBytes = TRUE)
}

edit_file <- function(file) {
  if (rstudioapi::hasFun("navigateToFile"))
    rstudioapi::navigateToFile(file)
  else
    utils::file.edit(file)
}





