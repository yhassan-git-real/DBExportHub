import os
import pandas as pd
import numpy as np
import json
from datetime import datetime
import tempfile
import uuid
import pathlib
import gc
from typing import List, Dict, Any, Optional
import xlsxwriter

from ..core.config import settings
from ..core.logger import export_logger, log_execution_time
from ..core.logging_utils import log_excel_completion

def create_filename(params, first_row_hs):
    """Create a filename for the Excel export based on the parameters"""
    # Extract month and year for filename
    from_month_str = str(params.fromMonth)
    to_month_str = str(params.toMonth)
    
    # Convert month number to month name
    month_names = {
        "01": "JAN", "02": "FEB", "03": "MAR", "04": "APR", 
        "05": "MAY", "06": "JUN", "07": "JUL", "08": "AUG", 
        "09": "SEP", "10": "OCT", "11": "NOV", "12": "DEC"
    }
    
    # Get month and year parts
    from_month = from_month_str[-2:]
    from_year = from_month_str[2:4]  # Get the last 2 digits of year (YYYY format)
    to_month = to_month_str[-2:]
    to_year = to_month_str[2:4]  # Get the last 2 digits of year (YYYY format)
    
    # Create month-year strings
    mon1 = month_names.get(from_month, "") + from_year
    mon2 = month_names.get(to_month, "") + to_year
    
    # Determine if we need to show a range or single month
    if mon1 == mon2:
        month_year = mon1
    else:
        month_year = mon1 + "-" + mon2
    
    # Build filename with all search parameters
    filename1 = ""
    
    # Add HS code if provided
    if params.hs and params.hs != "%":
        hs_code = params.hs.strip().replace(" ", "").split(",")[0]
        filename1 = filename1 + hs_code
    
    # Add product if provided
    if params.prod and params.prod != "%":
        filename1 = filename1 + "_" + params.prod.replace(" ", "_")
    
    # Add IEC if provided
    if params.iec and params.iec != "%":
        filename1 = filename1 + "_" + params.iec
    
    # Add exporter company if provided
    if params.expCmp and params.expCmp != "%":
        filename1 = filename1 + "_" + params.expCmp.replace(" ", "_")
    
    # Add foreign country if provided
    if params.forcount and params.forcount != "%":
        filename1 = filename1 + "_" + params.forcount.replace(" ", "_")
    
    # Add foreign importer name if provided
    if params.forname and params.forname != "%":
        filename1 = filename1 + "_" + params.forname.replace(" ", "_")
    
    # Add port if provided
    if params.port and params.port != "%":
        filename1 = filename1 + "_" + params.port.replace(" ", "_")
    
    # Remove leading underscore if present
    if filename1 and filename1[0] == "_":
        filename1 = filename1[1:]
    
    # If no parameters were provided, use default name
    if not filename1:
        if first_row_hs and first_row_hs[0]:
            # Extract the HS code from first row
            hs_code = str(first_row_hs[0]).strip()
            filename1 = hs_code[:8] if len(hs_code) > 8 else hs_code
        else:
            filename1 = "Export"
    
    # Final filename format: Parameters_MMMYYEXP.xlsx
    filename = f"{filename1}_{month_year}EXP.xlsx"
    return filename

def setup_excel_workbook(file_path):
    """Set up an Excel workbook with optimized settings for large datasets"""
    # Create a workbook with highly optimized settings for large datasets
    workbook_options = {
        'constant_memory': True,  # Use constant memory mode for reduced memory usage
        'use_zip64': True,       # Enable ZIP64 extensions for files > 4GB
        'default_date_format': 'dd-mmm-yy',  # Set default date format
        'tmpdir': settings.TEMP_DIR,  # Use temp directory for temporary files
        'in_memory': False,      # Don't store everything in memory
        'strings_to_numbers': False, # Preserve strings like leading zeros
        'strings_to_formulas': False,  # Don't convert strings to formulas (faster)
        'strings_to_urls': False,  # Don't convert strings to URLs (faster)
        'nan_inf_to_errors': True  # Convert NaN/Inf to Excel errors
    }
    
    # Create workbook with optimized settings
    workbook = xlsxwriter.Workbook(file_path, workbook_options)
    return workbook

def create_excel_formats(workbook):
    """Create formats for Excel workbook based on requirements"""
    # Define formats
    header_format = workbook.add_format({
        'bold': True,
        'font_name': 'Times New Roman',
        'font_size': 10,
        'border': 1, # Thin border
        'bg_color': '#4F81BD', # Keep existing header background
        'font_color': 'black', # Keep existing header font color
        'align': 'center',
        'valign': 'vcenter'
        # Wrap text is False by default for headers unless specified
    })
    
    data_format = workbook.add_format({
        'font_name': 'Times New Roman',
        'font_size': 10,
        'border': 1, # Thin border
        'valign': 'vcenter', # Align vertical center
        'text_wrap': False # Disable text wrapping
        # Let alignment default to left/right based on type
    })
    
    date_format = workbook.add_format({
        'font_name': 'Times New Roman',
        'font_size': 10,
        'border': 1, # Thin border
        'num_format': 'dd-mmm-yy',
        'valign': 'vcenter', # Align vertical center
        'text_wrap': False # Disable text wrapping
    })
    
    return header_format, data_format, date_format

def write_excel_headers(worksheet, columns, header_format):
    """Write headers to Excel worksheet"""
    # Write headers
    for col_idx, column in enumerate(columns):
        worksheet.write(0, col_idx, column, header_format)
    
    # Set row height for header
    worksheet.set_row(0, 20)  # Set header row height to 20

def write_data_to_excel(worksheet, cursor, data_format, date_format, operation_id, total_count):
    """Write data to Excel worksheet in batches (NOTE: This function might be unused)"""
    # Import here to avoid circular imports
    from ..core.operation_tracker import is_operation_cancelled
      # Process data in chunks with optimized approach for large datasets
    batch_size = settings.get_batch_size('export')  # Use export-specific batch size
    row_idx = 1  # Start from row 1 (after header)
    total_rows = 0
    
    # Check cancellation frequency - check every N rows for better performance
    cancellation_check_frequency = 1000
    rows_since_last_check = 0
    
    while True:
        # Check if operation has been cancelled before fetching and processing each batch
        if is_operation_cancelled(operation_id):
            export_logger.info(f"[{operation_id}] Operation cancelled during Excel data writing at row {total_rows}/{total_count}")
            raise Exception("Operation cancelled by user")
            
        chunk_start = datetime.now()
        rows = cursor.fetchmany(batch_size)
        if not rows:
            break
        
        # Write data to Excel
        for row in rows:
            # Check for cancellation periodically during row processing
            # This makes cancellation more responsive without checking on every single row
            rows_since_last_check += 1
            if rows_since_last_check >= cancellation_check_frequency:
                if is_operation_cancelled(operation_id):
                    export_logger.info(f"[{operation_id}] Operation cancelled during Excel data writing at row {total_rows}/{total_count}")
                    raise Exception("Operation cancelled by user")
                rows_since_last_check = 0
                
            # Only set row height for every 10th row to improve performance
            if row_idx % 10 == 0:
                worksheet.set_row(row_idx, 15)
            
            for col_idx, value in enumerate(row):
                # Use date format for column 3 (index 2)
                if col_idx == 2 and value:  # SB_Date column
                    worksheet.write(row_idx, col_idx, value, date_format)
                else:
                    worksheet.write(row_idx, col_idx, value, data_format)
            row_idx += 1
        
        rows_processed = len(rows)
        total_rows += rows_processed
    
    # Return the total number of rows processed
    return total_rows