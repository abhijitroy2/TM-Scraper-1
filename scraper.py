from urllib.parse import urlparse
from typing import List, Dict, Optional
from datetime import datetime
import pytz

import requests


HEADERS = {
    "Accept": "application/json, text/plain, */*",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Accept-Language": "en-US,en;q=0.5",
    "Connection": "keep-alive",
    "Host": "api.trademe.co.nz",
    "Origin": "https://www.trademe.co.nz",
    "Referer": "https://www.trademe.co.nz/",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-site",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0",
    # "x-trademe-uniqueclientid": "d65a2b4b-dfe3-4534-bc5e-ad50ccccb049"
}



def convert_date(date_str: str) -> str:
    date_str = date_str.split('(')[1].split(')')[0]
    date_str = datetime.fromtimestamp(int(date_str) / 1000)
    # change datetime object in  in current timezone date
    local_now = date_str.astimezone(pytz.timezone('Pacific/Auckland'))
    return local_now.strftime('%Y-%m-%d %H:%M:%S')


def scrape_listings(url: str) -> List[Dict]:
    """
    Scrape all listings from a given URL.
    """
    API_URL = 'https://api.trademe.co.nz/v1/search/property/residential.json'
    canonical_path = ''

    listings = []
    parsed = urlparse(url)
    path = parsed.path
    if path.split('/')[-1] == 'search' and len(path.split('/')) > 3:
        canonical_path = '/' + '/'.join(path.split('/')[2:-1])

    # convert url parameters to API parameters and combine any multiple values
    query = parsed.query
    api_params = {}
    for param in query.split('&'):
        if '=' in param:
            key, value = param.split('=', 1)
            if key in api_params:
                api_params[key] += ',' + value
            else:
                api_params[key] = value

    page = '1'
    api_params.update({
        'page': page,
        'rows': '22',
        'return_canonical': 'true',
        'return_metadata': 'true',
        'canonical_path': canonical_path,
        'return_variants': 'true',
        'snap_parameters': 'true'
    })
    get = requests.get(API_URL, params=api_params, headers=HEADERS)
    data = get.json()
    total = data.get('TotalCount', 0)
    print(f"Total listings found: {total}")
    listings.extend(data.get('List', []))
    total_pages = (total // 22) + (1 if total % 22 > 0 else 0)
    for page in range(2, total_pages + 1):
        print(f"  Fetching page {page}/{total_pages}")
        api_params['page'] = str(page)
        get = requests.get(API_URL, params=api_params, headers=HEADERS)
        data = get.json()
        listings.extend(data.get('List', []))

    return listings


def scrape_listing_details(listing: Dict) -> Dict:
    """
    Scrape detailed information for a single listing.
    """
    listing_details = {}
    listing_id = listing.get('ListingId')
    if not listing_id:
        return listing
    
    title = listing.get('Title', 'No Title')

    published_date_str = ''
    published_date_list = listing.get('PropertySearchListingsTag', [])
    if published_date_list and isinstance(published_date_list, list):
        published_date_str = published_date_list[0].get('Date')
    if published_date_str:
        published_date = convert_date(published_date_str)

    address = listing.get('Address', '')
    district = listing.get('District', '')
    region = listing.get('Region', '')
    suburb = listing.get('Suburb', '')
    complete_address = ', '.join(filter(None, [address, suburb, district, region]))
    geographic_loc = str(listing.get('GeographicLocation', ''))
    display_price = listing.get('PriceDisplay', '')

    listing_url = f'https://api.trademe.co.nz/v1/listings/{listing_id}.json?return_canonical=true&return_member_profile=true&return_variants=true&requestor=%7B%22type%22%3A%22human%22%7D&should_render_compliance_message=false&preferred_shipping_location=use_delivery_address'
    get = requests.get(listing_url, headers=HEADERS)
    listing_data = get.json()
    desc = listing_data.get('Body', '')
    attrs = listing_data.get('Attributes', [])
    if attrs:
        for attr in attrs:
            attr_name = attr.get('Name', '')
            attr_value = attr.get('Value', '')
            if attr_name == 'bathrooms':
                listing_details['Bathrooms'] = attr_value.split()[0] if attr_value else ''
            elif attr_name == 'rateable_value_(rv)':
                listing_details['Capital Value'] = attr_value
            elif attr_name == 'bedrooms':
                listing_details['Bedrooms'] = attr_value.split()[0] if attr_value else ''
            elif attr_name == 'land_area':
                listing_details['Area'] = attr_value

    prop_path = listing.get('CanonicalPath', '') 
    listing_details['Property URL'] = f'https://www.trademe.co.nz/a{prop_path}'

    estimates_url = f'https://api.trademe.co.nz/v1/property/research/estimates/{listing_id}.json'
    get = requests.get(estimates_url, headers=HEADERS)
    estimates_data = get.json()
    prop_estimates = estimates_data.get('PropertyEstimates', {})
    if prop_estimates:
        prop_estimate_value = prop_estimates.get('EstimatedMarketPriceRangeDisplay', '')
        listing_details['Estimated Market Price'] = prop_estimate_value
    
    rent_estimates = estimates_data.get('RentEstimates', {})
    if rent_estimates:
        rent_estimate_value = rent_estimates.get('EstimatedPricePerWeekRangeDisplay', '')
        listing_details['Estimated Weekly Rent'] = rent_estimate_value
    
    home_id = None
    prop_attrs = listing_data.get('PropertyAttributes', [])
    if prop_attrs:
        if prop_attrs[-1].get('Name', '') == 'homes_property_id':
            home_id = prop_attrs[-1].get('Value', '')
        else:
            for prop_attr in prop_attrs:
                if prop_attr.get('Name', '') == 'homes_property_id':
                    home_id = prop_attr.get('Value', '')
                    break

    beds = int(listing_details.get('Bedrooms', '1') or 1)
    if beds < 2:
        beds = 2

    if home_id:
        nearby_url = f'https://api.trademe.co.nz/v1/property/homes/nearby.json?property_id={home_id}&bedrooms_min={beds-1}&bedrooms_max={beds+1}&limit=10'
        nearby_get = requests.get(nearby_url, headers=HEADERS)
        nearby_data = nearby_get.json().get('Cards', [])

        nearby_properties = []
        for nearby_prop in nearby_data:
            nearby_prop_details = nearby_prop.get('PropertyDetails', {})
            if nearby_prop_details:
                nearby_address = nearby_prop_details.get('DisplayAddress', '')

            nearby_date = nearby_prop.get('Date', '').split('T')[0]
            nearby_price = nearby_prop.get('DisplayPrice', '')
            nearby_url = f"https://www.trademe.co.nz/a{nearby_prop.get('Url', '')}"
            nearby_properties.append(' ;; '.join(filter(None, [nearby_address, nearby_date, nearby_price, nearby_url])))

        listing_details['Nearby Properties'] = '\r\n'.join(nearby_properties)

    listing_details['Property Title'] = title
    listing_details['Listing Date'] = published_date if published_date_str else ''
    listing_details['Property Address'] = complete_address
    listing_details['Address'] = address
    listing_details['Suburb'] = suburb
    listing_details['District'] = district
    listing_details['Region'] = region
    listing_details['Geographic Location'] = geographic_loc
    listing_details['Display Price'] = display_price
    listing_details['Description'] = desc

    return listing_details
