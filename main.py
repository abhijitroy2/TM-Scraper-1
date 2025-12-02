import os
import pandas as pd
from pathlib import Path
from typing import List, Dict
from scraper import scrape_listings, scrape_listing_details


class ListingScraper:
    def __init__(self, input_file: str = "input.txt"):
        """
        Initialize the ListingScraper.
        
        Args:
            input_file: Path to the input file containing URLs
        """
        self.input_file = input_file
        self.output_dir = "output"
        self._create_output_directory()
        self.COLUMNS = [
            'Listing Date', 'Property Title', 'Property Address',
            'Bedrooms', 'Bathrooms', 'Area', 'Capital Value', 'Property URL',
            'Estimated Market Price', 'Estimated Weekly Rent', 'Display Price',
            'Geographic Location', 'Address', 'Suburb', 'District', 'Region',
            'Description', 'Nearby Properties'
        ]
    
    def _create_output_directory(self):
        """Create output directory if it doesn't exist."""
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
    
    def _extract_filename_from_url(self, url: str) -> str:
        """
        Extract filename from URL by splitting on '/' and using 6th and 7th values.
        
        Args:
            url: The URL to extract filename from
            
        Returns:
            Filename without extension
        """
        parts = url.strip('/').split('?')[0].split('/')
        if parts[-1] == 'search':
            filename = f"{parts[-3]}_{parts[-2]}"
        else:
            filename = "listings"
        return filename.replace(' ', '_')
    
    def _get_excel_filepath(self, url: str) -> str:
        """
        Get the full filepath for the Excel file based on URL.
        
        Args:
            url: The URL to generate filename from
            
        Returns:
            Full path to Excel file
        """
        filename = self._extract_filename_from_url(url)
        return os.path.join(self.output_dir, f"{filename}.xlsx")
    
    def _load_existing_data(self, filepath: str) -> pd.DataFrame:
        """
        Load existing Excel file if it exists.
        
        Args:
            filepath: Path to the Excel file
            
        Returns:
            DataFrame with existing data or empty DataFrame
        """
        if os.path.exists(filepath):
            try:
                return pd.read_excel(filepath)
            except Exception as e:
                print(f"Warning: Could not read existing file {filepath}: {e}")
                return pd.DataFrame()
        return pd.DataFrame()
    
    def _save_listings_to_excel(self, listings: List[Dict], url: str):
        """
        Save listings to Excel file, appending to existing data.
        
        Args:
            listings: List of listing dictionaries
            url: The URL these listings came from
        """
        if not listings:
            print(f"No listings found for {url}")
            return
        
        filepath = self._get_excel_filepath(url)
        
        # Load existing data
        existing_df = self._load_existing_data(filepath)
        
        # Create DataFrame from new listings
        new_df = pd.DataFrame(listings, columns=self.COLUMNS)
        
        # Append new data to existing data
        if not existing_df.empty:
            combined_df = pd.concat([existing_df, new_df], ignore_index=True)
        else:
            combined_df = new_df
        
        # Save to Excel
        combined_df.to_excel(filepath, index=False)
        print(f"Saved {len(listings)} listings to {filepath}")
    
    def read_urls_from_file(self) -> List[str]:
        """
        Read URLs from input file.
        
        Returns:
            List of URLs
        """
        urls = []
        if not os.path.exists(self.input_file):
            print(f"Error: {self.input_file} not found")
            return urls
        
        with open(self.input_file, 'r') as f:
            urls = [line.strip() for line in f if line.strip()]
        
        return urls
    
    def process_url(self, url: str):
        """
        Process a single URL: scrape listings and details, then save to Excel.
        
        Args:
            url: The URL to process
        """
        print(f"\nProcessing: {url}")

        listings = scrape_listings(url)
        
        if not listings:
            print(f"No listings found on {url}")
            return
        
        print(f"Found {len(listings)} listings")
        
        # Step 2: Scrape details for each listing
        detailed_listings = []
        for i, listing in enumerate(listings, 1):
            print(f"  Scraping details for listing {i}/{len(listings)}")
            listing_details = scrape_listing_details(listing)
            detailed_listings.append(listing_details)
        
        # Step 3: Save to Excel
        self._save_listings_to_excel(detailed_listings, url)
    
    def run(self):
        """Run the scraper for all URLs in input.txt"""
        urls = self.read_urls_from_file()
        
        if not urls:
            print("No URLs found in input.txt")
            return
        
        print(f"Found {len(urls)} URLs to process")
        
        for url in urls:
            try:
                self.process_url(url)
            except Exception as e:
                print(f"Error processing {url}: {e}")


if __name__ == "__main__":
    scraper = ListingScraper()
    scraper.run()
