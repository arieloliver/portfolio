# :chart_with_upwards_trend: Portfolio
A flashy display of my data science prowess
## System Requirements
   - [R 4.6.2](https://cran.r-project.org/bin/windows/base/old/)
   - [RStudio](https://posit.co/download/rstudio-desktop/)
   - [GDAL 3.7.0](https://gdal.org/download.html) (Leaflet dependency)
   - [Rtools 4.5](https://cran.r-project.org/bin/windows/Rtools/) (Windows only)
   
## R Environment
1. Clone this repository `https://github.com/arieloliver/portfolio.git`
2. Open the RStudio project `portfolio.RProj`
3. First time users need to activate the project by running `renv::activate()`
4. Run `renv::restore()` to download all dependencies
5. Load the portfolio package by running `devtools::load_all()` in the R console

## Render My Portfolio

1. Run `render_portfolio()` in the R console.
2. The default configuration renders the output in `/inst/output/`.

**Choose your own adventure when rendering my portfolio:**
  | Parameter | Description |
|---|---|
| `site_number` | &#8226; USGS stream gage number(s).<br>&#8226; Explore stream gages on the [National Water Information System](https://maps.waterdata.usgs.gov/mapper/index.html) web interface.<br>&#8226; A random, eligible site is selected when not specified by user.<br>&#8226; <b>Note:</b> The Rmarkdown portfolio format can only be rendered with a single stream gage.<br>&nbsp;&nbsp;If you would like to visualize mutliple stream gages simultaneously, specify `shiny = TRUE` |
| `state` | &#8226; A two letter abbreviation for a US state, e.g. `"CO"`<br>&#8226; Provide when you want a random stream gage selected within the given state. |
| `start_date` | &#8226; First day of data to be displayed in portfolio.<br>&#8226; Provide as `"YYYY-mm-dd"`, otherwise 1 month prior to today will be used. |
| `end_date` | &#8226; Last day of data to be displayed in portfolio.<br>&#8226; Provide as `"YYYY-mm-dd"`, otherwise today will be used. |
| `shiny` | &#8226; Should the portfolio be rendered as an R Shiny app?<br>&#8226; `FALSE` renders an Rmarkdown document (default)<br>&#8226; `TRUE` renders an R Shiny app on a local port |

#### Examples:
```r
# Renders an Rmarkdown portfolio using a random stream gage anywhere in the USA and displays the past 1 month of data.
render_portfolio()

# Renders an Rmarkdown portfolio using a random USGS stream gage located in Colorado, USA and displays the past 1 month of data.
render_portfolio(state = "CO")

# Renders an Rmarkdwon portfolio for stream gage 06752260 and displays all data from 2022.
render_portfolio(site_number = "USGS-06752260", start_date = "2022-01-01", end_date = "2022-12-31")

# Renders an R Shiny portfolio using three random stream gages in Colorado.
render_portfolio(state = "CO", shiny = TRUE)
```

#### The Final Product:
![image](https://github.com/arielreed/portfolio/assets/52611343/136b7fb5-e9fa-4561-b7ef-f833cdbbd2d1)


