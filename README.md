# Trade Me Listings Scraper

A Python-based web scraper for collecting and exporting listings from Trade Me website.

## Project Structure

```
trademe/
├── main.py           # Main scraper orchestrator
├── scraper.py        # Scraping functions
├── input.txt         # Input URLs (one per line)
├── output/           # Generated Excel files
├── requirements.txt  # Python dependencies
└── README.md         # This file
```

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure input URLs:**
   Edit `input.txt` and add the URLs you want to scrape (one URL per line):
   ```
   https://example.com/listings/category/computers/laptops
   https://example.com/listings/category/electronics/phones
   ```

## Usage

Run the scraper:
```bash
python main.py
```

The script will:
1. Read URLs from `input.txt`
2. Extract filename from each URL
3. Scrape all listings and their details
4. Save results to `output/{filename}.xlsx`
5. On subsequent runs, append new data to existing files (delete old files if you want to generate completely new files)

## Output

Excel files are created in the `output/` directory with:
- One file per input URL
- Filename derived from URL path segments
- All listing details as columns
- New data appended on subsequent runs

