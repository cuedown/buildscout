# Listing data format

BuildScout can import vehicle candidates from JSON or CSV.

## JSON

The easiest way to guarantee compatibility is to export records from BuildScout and re-import them later.

A vehicle record contains fields equivalent to:

```json
{
  "source": "Example auction",
  "title": "2002 BMW 330i manual project",
  "year": 2002,
  "make": "BMW",
  "model": "330i",
  "price": 2500,
  "location": "Calgary, AB",
  "drivetrain": "RWD",
  "transmission": "Manual",
  "runs": true,
  "towRequired": false,
  "horsepower": 225,
  "notes": "Needs suspension work",
  "url": "https://example.invalid/listing"
}
```

BuildScout's exported JSON also includes stable record IDs plus risk and strength metadata.

## CSV

Supported columns:

```
source,title,year,make,model,price,location,drivetrain,transmission,runs,towrequired,horsepower,notes,url
```

Only `title` is required. Unknown values can be left blank.

Example:

```csv
source,title,year,make,model,price,location,drivetrain,transmission,runs,towrequired,horsepower,notes,url
Community,2007 BMW 328i 6MT,2007,BMW,328i,2500,Edmonton AB,RWD,Manual,true,false,230,Needs suspension work,https://example.invalid/e90
```

## Trust model

Imported data is treated as leads, not truth.

Vehicle history, title status, mechanical condition, fitment, event legality, and safety-critical modifications should always be independently verified before money or tools come out.
