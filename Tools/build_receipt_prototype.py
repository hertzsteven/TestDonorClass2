"""Prototype receipt PDF generator (Approach B — paragraph-level fields).

Takes the scanned Colel Chabad receipt and produces a PDF with the same
look (scan rendered as background image) plus interactive AcroForm
fields placed where the variable / "program-entered" parts go.

Field model (Approach B):
    The body paragraphs are themselves variable, so amount + dedication
    are not standalone fields. Instead, the Swift app composes the full
    paragraph text from semantic variables and stuffs it into a single
    multiline field per paragraph.

Outputs:
    Receipt_Prototype.pdf        — invisible fields (real prototype)
    Receipt_Prototype_Debug.pdf  — same fields, drawn as orange boxes
                                   so positions can be eyeballed
    Receipt_Prototype_Filled.pdf — sample data filled into the fields

Usage:
    python build_receipt_prototype.py
"""

from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
from pathlib import Path

import pymupdf
from pypdf import PdfReader, PdfWriter
from reportlab.lib.colors import Color
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas


SOURCE_PDF = Path("/Users/stevenhertz/Downloads/Scan 4-29-26, 2-08-10 PM.pdf")
TOOLS_DIR = Path(__file__).parent
OUTPUT_PROTOTYPE = TOOLS_DIR / "Receipt_Prototype.pdf"
OUTPUT_DEBUG = TOOLS_DIR / "Receipt_Prototype_Debug.pdf"
OUTPUT_FILLED = TOOLS_DIR / "Receipt_Prototype_Filled.pdf"

PAGE_WIDTH_PT = 613.0
PAGE_HEIGHT_PT = 792.0

RENDER_DPI = 200


@dataclass(frozen=True)
class FieldSpec:
    name: str
    x: float
    y: float
    width: float
    height: float
    max_len: int
    multiline: bool
    tooltip: str


# Coordinates are in PDF points from the bottom-left of the page.
# Read off the rendered scan: 1188-pixel-tall image rendered at 1.5x zoom,
# so pdf_y = (1188 - pixel_y) / 1.5 and pdf_x = pixel_x / 1.5.
FIELDS: list[FieldSpec] = [
    # ───── Top section: thank-you letter ─────
    FieldSpec("date_english",         72, 661, 180, 14,  40, False, "Top date — English"),
    FieldSpec("date_hebrew",          72, 644, 180, 14,  40, False, "Top date — Hebrew"),
    FieldSpec("greeting",             72, 596, 460, 14, 100, False, "'Dear ___,' greeting"),
    FieldSpec("letter_body",          72, 488, 525, 110, 1500, True, "Top thank-you paragraph(s) — body of the letter"),
    # ───── Bottom section: receipt ─────
    FieldSpec("receipt_date",         72, 180, 160, 14,  40, False, "Receipt date"),
    FieldSpec("receipt_number",      400, 180, 180, 14,  20, False, "Receipt number"),
    FieldSpec("receipt_body",         40, 120, 555, 38, 400, True, "Receipt sentence — donation amount + dedication composed in"),
    FieldSpec("donor_name",           40,  66, 420, 14,  80, False, "Donor full name"),
    FieldSpec("donor_street",         40,  49, 420, 14,  80, False, "Donor street address"),
    FieldSpec("donor_city_state_zip", 40,  32, 420, 14,  80, False, "Donor city, state, ZIP"),
]


# Whiteout regions — explicit rectangles drawn over the scan to erase the
# original variable text before form fields render. These are sized
# GENEROUSLY to cover all original variable text in each section, but
# carefully to NOT cover static elements (letterheads, "Sincerely,",
# signature, "No goods or services" tax line, footer).
#
# Each entry: (x, y, width, height) in PDF points.
WHITEOUT_REGIONS: list[tuple[float, float, float, float]] = [
    # ───── Top section ─────
    # Dates (English + Hebrew) area
    (40, 635, 280, 45),
    # Greeting line
    (40, 588, 510, 22),
    # Letter body block (covers all 3 body paragraphs, but NOT "Sincerely,")
    (40, 455, 555, 145),
    # ───── Bottom section ─────
    # Receipt date + receipt number row (carefully avoids letterhead address)
    (40, 160, 555, 33),
    # Receipt body sentence (2 lines)
    (20, 105, 580, 55),
    # Donor name / street / city block (carefully avoids "No goods…" tax line)
    (20,  18, 480, 70),
]


# Color sampled from clean paper area in the scan (avg of mid-page samples).
PAPER_COLOR = (0.880, 0.885, 0.845)


def render_scan_to_png_bytes(scan_path: Path, dpi: int = RENDER_DPI) -> bytes:
    """Render the first page of the source PDF to PNG bytes."""
    doc = pymupdf.open(scan_path)
    try:
        page = doc.load_page(0)
        zoom = dpi / 72.0
        matrix = pymupdf.Matrix(zoom, zoom)
        pixmap = page.get_pixmap(matrix=matrix, alpha=False)
        return pixmap.tobytes("png")
    finally:
        doc.close()


def build_pdf(background_png: bytes, output_path: Path, *, debug: bool) -> None:
    """Write a PDF with the scan as background + AcroForm fields on top.

    When debug=True, fields are drawn with a visible orange border + light
    fill so positions can be eyeballed against the underlying receipt.
    When debug=False, fields are invisible — only typed values will show.
    """
    c = canvas.Canvas(str(output_path), pagesize=(PAGE_WIDTH_PT, PAGE_HEIGHT_PT))

    background = ImageReader(BytesIO(background_png))
    c.drawImage(
        background,
        0, 0,
        width=PAGE_WIDTH_PT,
        height=PAGE_HEIGHT_PT,
        preserveAspectRatio=False,
        anchor="sw",
    )

    # Erase the scan's existing variable text using explicit whiteout
    # regions, so filled field values don't double up with the sample
    # data baked into the scan.
    c.setFillColorRGB(*PAPER_COLOR)
    c.setStrokeColorRGB(*PAPER_COLOR)
    for wx, wy, ww, wh in WHITEOUT_REGIONS:
        c.rect(wx, wy, ww, wh, fill=1, stroke=0)

    form = c.acroForm

    if debug:
        border_color = Color(0.85, 0.45, 0.05)
        fill_color = Color(1.0, 0.97, 0.80, alpha=0.6)
    else:
        border_color = Color(1.0, 1.0, 1.0, alpha=0.0)
        fill_color = Color(1.0, 1.0, 1.0, alpha=0.0)

    text_color = Color(0.10, 0.10, 0.10)

    for spec in FIELDS:
        kwargs = dict(
            name=spec.name,
            tooltip=spec.tooltip,
            x=spec.x,
            y=spec.y,
            width=spec.width,
            height=spec.height,
            fontSize=10,
            maxlen=spec.max_len,
            borderStyle="inset",
            borderWidth=1 if debug else 0,
            borderColor=border_color,
            fillColor=fill_color,
            textColor=text_color,
            forceBorder=debug,
        )
        if spec.multiline:
            kwargs["fieldFlags"] = "multiline"
        form.textfield(**kwargs)

    c.save()


def fill_sample_data(prototype_path: Path, output_path: Path) -> None:
    """Produce a copy of the prototype PDF with sample values filled in."""
    reader = PdfReader(str(prototype_path))
    writer = PdfWriter(clone_from=reader)

    sample = {
        "date_english": "April 15, 2026",
        "date_hebrew": "28 Nisan 5786",
        "greeting": "Dear Chaim and Yospa,",
        "letter_body": (
            "I want to express my heartfelt gratitude for your generous "
            "donation of $36.00. Your contribution is deeply appreciated "
            "and plays a crucial role in supporting Colel Chabad's mission "
            "to assist those in need in Israel.\n\n"
            "Your partnership makes a significant difference in their "
            "lives, providing them with hope and assistance during "
            "challenging times.\n\n"
            "May you be blessed abundantly for your kindness and generosity."
        ),
        "receipt_date": "April 15, 2026",
        "receipt_number": "A2 18993",
        "receipt_body": (
            "We have gratefully received your generous donation of $36.00 "
            "in loving memory of Chaim Gedalya ben Yehoshua, OBM."
        ),
        "donor_name": "Rabbi and Mrs. Chaim Werner",
        "donor_street": "1442 45th St",
        "donor_city_state_zip": "Brooklyn, NY 11219",
    }

    writer.update_page_form_field_values(writer.pages[0], sample)

    with open(output_path, "wb") as fh:
        writer.write(fh)


def verify_fields(pdf_path: Path) -> list[str]:
    """Return the names of AcroForm text fields found in the PDF."""
    reader = PdfReader(str(pdf_path))
    fields = reader.get_fields() or {}
    return sorted(fields.keys())


def main() -> None:
    if not SOURCE_PDF.exists():
        raise SystemExit(f"Source PDF not found: {SOURCE_PDF}")

    background_png = render_scan_to_png_bytes(SOURCE_PDF)
    build_pdf(background_png, OUTPUT_PROTOTYPE, debug=False)
    build_pdf(background_png, OUTPUT_DEBUG, debug=True)
    fill_sample_data(OUTPUT_PROTOTYPE, OUTPUT_FILLED)

    found = verify_fields(OUTPUT_PROTOTYPE)
    print(f"Wrote: {OUTPUT_PROTOTYPE}")
    print(f"       {OUTPUT_DEBUG}")
    print(f"       {OUTPUT_FILLED}")
    print(f"Fields ({len(found)}):")
    for name in found:
        print(f"  - {name}")


if __name__ == "__main__":
    main()
