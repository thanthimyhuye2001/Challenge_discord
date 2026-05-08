# =============================================================================
# Cào job data từ TopCV cho 3 nhóm link
# Tác giả: Thân Thị Mỹ Huyền
# Crawl job listings từ TopCV lĩnh vực data
# =============================================================================

'''
── KHUNG CHÍNH ────────────────────────────────────────────────────────────────

1. IMPORT                           Khai báo các thư viện/module
2. CẤU HÌNH & HỆ THỐNG              Các biến toàn cục quan trọng
3. LOGGING                          Khai báo nhật ký -> theo dõi & gỡ lỗi
4. CÁC FUNCTION LẤY TỪNG TRƯỜNG     Khai báo các function để lấy từng trường
5. VÒNG LẶP CHÍNH                   Cào url trong 1 page -> cào chi tiết từng url -> lưu vào CSV -> next page
6. ENTRY POINT                      Khối lệnh kích hoạt hàm main() -> thực thi toàn bộ program
───────────────────────────────────────────────────────────────────────────────
'''

# ── 1. IMPORT ────────────────────────────────────────────────────────────────────

import time
import re
import datetime
import csv
import logging
import sys
import os
import random

import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from bs4 import BeautifulSoup


# ── 2. CẤU HÌNH & HỆ THỐNG ───────────────────────────────────────────────────────
KEYWORDS = [
    "Data Analyst", "Business Intelligence", "Data Visualization", "Product Analyst", "Marketing Analyst",
    "Data Engineer", "Data Architect", "Data Warehouse", "ETL", "Analytics Engineer", "Cloud Data",
    "Data Scientist", "Machine Learning", "AI Engineer", "NLP Engineer", "Computer Vision Engineer", "Algorithm Engineer", "MLOps Engineer",
    "Database Administrator", "Data Modeler", "Data Governance Specialist", "Data Quality Analyst", "Database Developer",
    "Big Data Engineer", "Quantitative Analyst"
]


BASE_URL_TEMPLATE = "https://www.topcv.vn/tim-viec-lam-{keyword}?sort=new&type_keyword=1&page={page}"

MAX_PAGES = 60  # Giới hạn tối đa số page để crawl cho mỗi keyword

OUTPUT_CSV = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Data_raw", "data_topcv.csv")

# Config stdout to use UTF-8 instead of cp1252 on Windows
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


# ── 3. LOGGING ───────────────────────────────────────────────────────────────────

logging.basicConfig(
    filename=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Logging", "logging_topcv.log"),
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    encoding='utf-8'
)


# ── 4. CÁC FUNCTION LẤY TỪNG TRƯỜNG ─────────────────────────────────────────────

def get_total_pages(soup):
    """Hàm lấy tổng số trang từ HTML của TopCV"""
    try:
        paginate_span = soup.find('span', id='job-listing-paginate-text')
        if paginate_span:
            text = paginate_span.get_text(strip=True)
            match_numbers = re.findall(r'\d+', text)
            if len(match_numbers) >= 2:
                return int(match_numbers[1])
        return 1 
    except Exception as e:
        logging.error(f"Lỗi khi lấy tổng số trang: {e}")
        return 1


def get_posted_date_from_text(raw_text):
    """Tính toán ngày đăng từ văn bản tương đối."""
    try:
        now = datetime.datetime.now()
        raw_text_lower = raw_text.lower()
        if any(x in raw_text_lower for x in ['hôm nay', 'giờ', 'phút', 'giây']):
            posted_date = now
        else:
            match = re.search(r'\d+', raw_text)
            if not match:
                return None
            number = int(match.group())
            
            if 'ngày' in raw_text_lower:
                posted_date = now - datetime.timedelta(days=number)
            elif 'tuần' in raw_text_lower:
                posted_date = now - datetime.timedelta(days=number * 7)            
            elif 'tháng' in raw_text_lower:
                posted_date = now - datetime.timedelta(days=number * 30)
            else:
                return None
                
        return posted_date.strftime('%Y-%m-%d')
    except Exception:
        return None


def get_job_links_and_dates(soup):
    """
    Quét trang danh sách công việc (trang tổng), lấy ra Dictionary chứa:
    Key: Link công việc (job_url)
    Value: Ngày đăng/cập nhật (posted_date)
    """
    job_link_date_dict = {}
    try:
        job_list_box = soup.find("div", class_="job-list-search-result")
        if not job_list_box:
            return job_link_date_dict

        job_tag_groups = job_list_box.find_all('div', class_=re.compile(r'job-item-search-result'))
        for group in job_tag_groups:
            link_tag = group.select_one('h3.title a[href]')
            update_tag = group.find('label', class_=re.compile(r'label-update'))
            
            if link_tag and update_tag:
                raw_link = link_tag.get('href')
                clean_link = raw_link.split('?')[0] 
                
                posted_date_text = update_tag.get_text(separator=" ", strip=True)
                posted_date = get_posted_date_from_text(posted_date_text) 
                
                if clean_link:
                    job_link_date_dict[clean_link] = posted_date
                    
        return job_link_date_dict
    except Exception as e:
        logging.error(f"Lỗi khi cào link và date ở trang tổng: {e}")
        return job_link_date_dict


# Các Function chi tiết riêng lẻ

def get_title(soup):
    try:
        header_box = soup.find('div', id='header-job-info')
        if header_box:
            title_tag = header_box.find('h1')
            if title_tag:
                return title_tag.get_text(separator=' ', strip=True)
        return None
    except Exception as e:
        logging.error(f"Lỗi khi lấy title: {e}")
        return None

def get_company(soup):
    try:
        company_tag = soup.find('div', class_='company-name-label')
        if company_tag:
            return company_tag.get_text(strip=True)
        return None
    except Exception:
        return None


def get_location(soup):
    try:
        header_box = soup.find('div', id='header-job-info')
        if header_box:
            location_box = header_box.find('div', class_='section-location')
            if location_box:
                # Sửa lại cho chắc cú pháp, phòng khi bị xê dịch
                # value_tag = location_box.find('div', class_='job-detail__info--section-content-value')
                
                pattern_value_tag = re.compile(r'(?=.*job-detail)(?=.*info)(?=.*section-content-value)', re.IGNORECASE)
                value_tag = location_box.find('div', class_=pattern_value_tag)
                if value_tag:
                    return value_tag.get_text(strip=True)
        return None
    except Exception:
        return None


def get_salary(soup):
    try:
        header_box = soup.find('div', id='header-job-info')
        if header_box:
            salary_box = header_box.find('div', class_='section-salary')
            if salary_box:
                # value_tag = salary_box.find('div', class_='job-detail__info--section-content-value')
                pattern_value_tag = re.compile(r'(?=.*job-detail)(?=.*info)(?=.*section-content-value)', re.IGNORECASE)
                value_tag = salary_box.find('div', class_=pattern_value_tag)
                
                if value_tag:
                    return value_tag.get_text(strip=True)
        return None
    except Exception:
        return None


def get_experience(soup):
    try:
        header_box = soup.find('div', id='header-job-info')
        if header_box:
            exp_box = header_box.find('div', class_='section-experience')
            if exp_box:
                # value_tag = exp_box.find('div', class_='job-detail__info--section-content-value')
                pattern_value_tag = re.compile(r'(?=.*job-detail)(?=.*info)(?=.*section-content-value)', re.IGNORECASE)
                value_tag = exp_box.find('div', class_=pattern_value_tag)
                
                if value_tag:
                    return value_tag.get_text(strip=True)
        return None
    except Exception:
        return None


def get_deadline_date(soup):
    try:
        header_box = soup.find('div', id='header-job-info')
        if header_box:
            deadline_tag = header_box.find('div', class_=re.compile(r'deadline-date'))
            if deadline_tag:
                return deadline_tag.get_text(strip=True)
        return None
    except Exception:
        return None


def get_field(soup):
    try:
        company_industry_tag = soup.find('div', class_=re.compile(r'company-field'))
        if company_industry_tag:
            company_industry_value = company_industry_tag.find('div', class_='company-value')
            if company_industry_value:
                return company_industry_value.get_text(strip=True)
        return None
    except Exception:
        return None


def job_general_info(soup):
    """
    Quét HTML 1 lần, gom toàn bộ thông tin thành Dictionary từ box-general-content
    """
    job_info = {}
    try:
        content_box = soup.find('div', class_='box-general-content')
        if content_box:
            groups = content_box.find_all('div', class_='box-general-group-info')
            for group in groups:
                title_tag = group.find('div', class_='box-general-group-info-title')
                value_tag = group.find('div', class_='box-general-group-info-value')
                
                if title_tag and value_tag:
                    title_text = title_tag.get_text(separator=" ", strip=True)
                    value_text = value_tag.get_text(separator=" ", strip=True)
                    job_info[title_text] = value_text
        return job_info
    except Exception as e:
        logging.error(f"Lỗi khi lấy general_info: {e}")
        return job_info 


def get_job_expertise(soup):
    """Lấy danh sách các thẻ chuyên môn (Expertise / Tags) của công việc."""
    try:
        job_info_detail_box = soup.find('div', id='box-job-information-detail')
        if job_info_detail_box:
            expertise_tag = job_info_detail_box.find(
                'div', 
                class_=re.compile(r'group-name'), 
                string=re.compile(r'Chuyên môn:', re.IGNORECASE)
            )
            if expertise_tag:
                parent_expertise = expertise_tag.parent 
                if parent_expertise:
                    expertise_list = parent_expertise.find('div', class_=re.compile(r'group-list-tag-scroll'))
                    if expertise_list:
                        a_tags = expertise_list.find_all('a')
                        tags_list = [a.get_text(strip=True) for a in a_tags if a.get_text(strip=True)]
                        if tags_list:
                            return ", ".join(tags_list)
        return None 
    except Exception as e:
        logging.error(f"Lỗi khi lấy job_expertise: {e}")
        return None





def extract_paragraph_content(soup, heading_keyword):
    """
    Hàm đa năng: Tìm thẻ h3 chứa keyword, sau đó lấy toàn bộ text 
    của các thẻ anh em nằm dưới nó trong cùng 1 div.
    """
    try:
        job_info_detail_box = soup.find('div', id='box-job-information-detail')
        if not job_info_detail_box:
            return None
            
        h3_tag = job_info_detail_box.find('h3', string=re.compile(heading_keyword, re.IGNORECASE))
        if h3_tag:
            content_parts = []
            for sibling in h3_tag.find_next_siblings():
                text = sibling.get_text(separator=' ', strip=True)
                if text:
                    content_parts.append(text)
            
            raw_text = ' '.join(content_parts)
            clean_text = re.sub(r'[•\-\*·●]', '', raw_text)
            clean_text = clean_text.replace('\xa0', ' ')
            final_text = ' '.join(clean_text.split())
            
            if final_text.startswith(('-', '=', '+', '@')):
                final_text = "'" + final_text
            return final_text
        return None
    except Exception as e:
        logging.error(f"Lỗi khi lấy {heading_keyword}: {e}")
        return None

def get_job_description(soup):
    return extract_paragraph_content(soup, "Mô tả công việc")

def get_job_requirements(soup):
    return extract_paragraph_content(soup, "Yêu cầu ứng viên")

def get_benefits(soup):
    return extract_paragraph_content(soup, "Quyền lợi")


# ==========================================
# NHÓM 1 (NON-VIP): CÓ THẺ <h1 class="title">
# ==========================================

def get_job_head_info_1(soup):
    info = {}
    try:
        pattern = re.compile(r'(?=.*premium-job-basic-information)(?=.*title)', re.IGNORECASE)
        title_tag = soup.find('h2', class_=pattern)
        if title_tag:
            head_box = title_tag.parent
            pattern_big_groups = re.compile(r'(?=.*premium-job-basic-information)(?=.*sections)', re.IGNORECASE)
            big_group = head_box.find('div', class_=pattern_big_groups)
            if big_group:
                groups = big_group.find_all('div', class_='basic-information-item__data')
                for group in groups:
                    pattern_lable = re.compile(r'(?=.*basic-information-item)(?=.*label)', re.IGNORECASE)
                    pattern_value = re.compile(r'(?=.*basic-information-item)(?=.*value)', re.IGNORECASE)
                    lable_tag = group.find('div', class_=pattern_lable)
                    value_tag = group.find('div', class_=pattern_value)
                    if lable_tag and value_tag:
                        info[lable_tag.get_text(separator=" ", strip=True)] = value_tag.get_text(separator=" ", strip=True)
    except Exception as e:
        logging.error(f"Lỗi khi lấy job_head_info_1: {e}")
    return info

def get_job_general_info_1(soup):
    info = {}
    try:
        pattern = re.compile(r'(?=.*premium-job-general-information)(?=.*title)', re.IGNORECASE)
        title_box_tag = soup.find('h2', class_=pattern, string=re.compile(r'Thông tin chung', re.IGNORECASE))
        if title_box_tag:
            general_content_box = title_box_tag.parent
            if general_content_box:
                info_blocks = general_content_box.find_all('div', class_="general-information-data")
                for block in info_blocks:
                    pattern_lable = re.compile(r'(?=.*general-information-data)(?=.*label)', re.IGNORECASE)
                    pattern_value = re.compile(r'(?=.*general-information-data)(?=.*value)', re.IGNORECASE)
                    lable_tag = block.find('div', class_=pattern_lable)
                    value_tag = block.find('div', class_=pattern_value)
                    if lable_tag and value_tag:
                        info[lable_tag.get_text(separator=" ", strip=True)] = value_tag.get_text(separator=" ", strip=True)
    except Exception as e:
        logging.error(f"Lỗi khi lấy job_general_info_1: {e}")
    return info

def extract_paragraph_content_1(soup, heading_keyword):
    try:
        pattern_class = re.compile(r'(?=.*premium-job-description)(?=.*box)(?=.*title)', re.IGNORECASE)
        pattern_string = re.compile(rf'{heading_keyword}', re.IGNORECASE)
        h2_tag = soup.find('h2', class_=pattern_class, string=pattern_string)
        if h2_tag:
            box_tag = h2_tag.parent 
            if box_tag:
                pattern_content_class = re.compile(r'(?=.*premium-job-description)(?=.*box)(?=.*content)', re.IGNORECASE)
                content_tag = box_tag.find('div', class_=pattern_content_class)
                if content_tag:
                    raw_text = content_tag.get_text(separator=' ', strip=True)
                    clean_text = re.sub(r'[•\*●\-\+\−]', '', raw_text)
                    final_text = ' '.join(clean_text.split())
                    if final_text.startswith(('-', '=', '+', '@')):
                        final_text = "'" + final_text
                    return final_text
    except Exception as e:
        logging.error(f"Lỗi extract_paragraph_content_1 {heading_keyword}: {e}")
    return None

def get_title_1(soup):
    try:
        pattern = re.compile(r'(?=.*premium-job-basic-information)(?=.*title)', re.IGNORECASE)
        title_tag = soup.find('h2', class_=pattern)
        if title_tag:
            return title_tag.get_text(separator=' ', strip=True)
    except Exception:
        pass
    return None

def get_salary_1(soup):           return get_job_head_info_1(soup).get('Mức lương')
def get_location_1(soup):         return get_job_head_info_1(soup).get('Địa điểm')
def get_years_experience_1(soup): return get_job_head_info_1(soup).get('Kinh nghiệm')
def get_level_1(soup):            return get_job_general_info_1(soup).get('Cấp bậc')
def get_education_level_1(soup):  return get_job_general_info_1(soup).get('Học vấn')
def get_hire_number_1(soup):      return get_job_general_info_1(soup).get('Số lượng tuyển')
def get_job_type_1(soup):         return get_job_general_info_1(soup).get('Hình thức làm việc')
def get_job_deadline_1(soup):     return get_job_general_info_1(soup).get('Hạn nộp hồ sơ')

def get_company_1(soup):
    try:
        tag = soup.find('h1', class_="title")
        return tag.get_text(strip=True) if tag else None
    except Exception: return None

def get_expertise_1(soup):
    try:
        pattern_class = re.compile(r'(?=.*job-tags)(?=.*group-name)', re.IGNORECASE)
        pattern_string = re.compile(r'Chuyên môn', re.IGNORECASE)
        expertise_tag = soup.find('div', class_=pattern_class, string=pattern_string)
        if expertise_tag and expertise_tag.parent:
            expertise_list = expertise_tag.parent.find('div', class_=re.compile(r'group-list-tag-scroll'))
            if expertise_list:
                a_tags = expertise_list.find_all('a')
                tags_list = [a.get_text(strip=True) for a in a_tags if a.get_text(strip=True)]
                if tags_list:
                    return ", ".join(tags_list).replace('Chuyên môn', '').strip()
    except Exception: pass
    return None

def get_job_description_1(soup):  return extract_paragraph_content_1(soup, "Mô tả công việc")
def get_requirements_1(soup):     return extract_paragraph_content_1(soup, "Yêu cầu ứng viên")
def get_benefits_1(soup):         return extract_paragraph_content_1(soup, "Quyền lợi được hưởng")


# ==========================================
# NHÓM 2 (VIP): KHÔNG CÓ THẺ <h1 class="title">
# ==========================================

def get_job_general_info_2(soup):
    info = {}
    try:
        info_title_tag = soup.find('h2', class_="title", string="Thông tin")
        if info_title_tag:
            info_box = info_title_tag.parent
            if info_box:
                group_box = info_box.find_all('div', class_='box-item')
                for block in group_box:
                    lable_tag = block.find('strong')
                    value_tag = block.find('span')
                    if lable_tag and value_tag:
                        info[lable_tag.get_text(separator=" ", strip=True)] = value_tag.get_text(separator=" ", strip=True)
    except Exception as e:
        logging.error(f"Lỗi khi lấy job_general_info_2: {e}")
    return info

def extract_paragraph_content_2(soup, heading_keyword):
    try:
        pattern_string = re.compile(rf'{heading_keyword}', re.IGNORECASE)
        h2_tag = soup.find('h2', class_='title', string=pattern_string)
        if h2_tag and h2_tag.parent:
            box_tag = h2_tag.parent 
            content_tag = box_tag.find('div', class_='content-tab')
            if content_tag:
                raw_text = content_tag.get_text(separator=' ', strip=True)
                clean_text = re.sub(r'[•\*●\-\+\−]', '', raw_text)
                final_text = ' '.join(clean_text.split())
                if final_text.startswith(('-', '=', '+', '@')):
                    final_text = "'" + final_text
                return final_text
    except Exception as e:
        logging.error(f"Lỗi extract_paragraph_content_2 {heading_keyword}: {e}")
    return None

def get_title_2(soup):
    try:
        header_box = soup.find('div', class_="box-header")
        if header_box:
            title_tag = header_box.find('h2', class_='title')
            if title_tag:
                return title_tag.get_text(separator=' ', strip=True)
    except Exception: pass
    return None

def get_job_deadline_2(soup):
    try:
        header_box = soup.find('div', class_="box-header")
        if header_box:
            deadline_tag = header_box.find('span', class_="deadline")
            if deadline_tag:
                raw_text = deadline_tag.get_text(separator=' ', strip=True)
                now = datetime.datetime.now()
                if 'hôm nay' in raw_text or 'giờ' in raw_text or 'phút' in raw_text or 'giây' in raw_text:
                    deadline_date = now
                else:
                    match = re.search(r'\d+', raw_text)
                    if not match: return None
                    number = int(match.group())
                    if 'ngày' in raw_text: deadline_date = now + datetime.timedelta(days=number)
                    elif 'tuần' in raw_text: deadline_date = now + datetime.timedelta(days=number * 7)            
                    elif 'tháng' in raw_text: deadline_date = now + datetime.timedelta(days=number * 30)
                    else: return None
                return deadline_date.strftime("%d/%m/%Y")
    except Exception: pass
    return None

def get_salary_2(soup):           return get_job_general_info_2(soup).get('Mức lương')

PROVINCES = {
    "tuyên quang": "Tuyên Quang", "lào cai": "Lào Cai", "thái nguyên": "Thái Nguyên", "phú thọ": "Phú Thọ",
    "bắc ninh": "Bắc Ninh", "hưng yên": "Hưng Yên", "hải phòng": "Hải Phòng", "ninh bình": "Ninh Bình",
    "quảng trị": "Quảng Trị", "đà nẵng": "Đà Nẵng", "quảng ngãi": "Quảng Ngãi", "gia lai": "Gia Lai",
    "khánh hòa": "Khánh Hòa", "điện biên": "Điện Biên", "hà nội": "Hà Nội", "hà tĩnh": "Hà Tĩnh",
    "lạng sơn": "Lạng Sơn", "lai châu": "Lai Châu", "nghệ an": "Nghệ An", "quảng ninh": "Quảng Ninh",
    "sơn la": "Sơn La", "thanh hóa": "Thanh Hóa", "cao bằng": "Cao Bằng", "huế": "Huế",
    "lâm đồng": "Lâm Đồng", "đắk lắk": "Đắk Lắk", "hồ chí minh": "Hồ Chí Minh", "đồng nai": "Đồng Nai",
    "tây ninh": "Tây Ninh", "cần thơ": "Cần Thơ", "vĩnh long": "Vĩnh Long", "đồng tháp": "Đồng Tháp",
    "cà mau": "Cà Mau", "an giang": "An Giang"
}

def extract_new_location_2(address_text):
    if not address_text:
        return None
    text = address_text.lower()
    text = text.replace("việt nam", "").replace("vietnam", "")
    parts = re.split(r'[,|.]', text)
    for part in reversed(parts):
        clean_part = part.strip()
        clean_part = re.sub(r'^(thành phố|tp\.|tp|tỉnh)\s+', '', clean_part).strip()
        if clean_part in PROVINCES:
            return PROVINCES[clean_part] 
    return None

def get_location_2(soup):
    try:
        box_footer = soup.find('div', class_='footer-info')
        if box_footer:
            address_label = box_footer.find('div', class_='footer-info-title', string='Địa chỉ:')
            if address_label:
                address_content = address_label.find_next_sibling('div', class_='footer-info-content')
                if address_content:
                    address_text = address_content.text.strip()
                    if address_text:
                        return extract_new_location_2(address_text)    
    except Exception:
        pass
    return None

def get_years_experience_2(soup): return get_job_general_info_2(soup).get('Kinh nghiệm')
def get_level_2(soup):            return get_job_general_info_2(soup).get('Cấp bậc')
def get_education_level_2(soup):  return get_job_general_info_2(soup).get('Học vấn')
def get_hire_number_2(soup):      return get_job_general_info_2(soup).get('Số lượng tuyển')
def get_job_type_2(soup):         return get_job_general_info_2(soup).get('Hình thức làm việc')

def get_company_2(soup):
    try:
        tag = soup.find('div', class_="footer-info-content footer-info-company-name")
        return tag.get_text(strip=True) if tag else None
    except Exception: return None

def get_expertise_2(soup):
    try:
        pattern_class = re.compile(r'(?=.*job-tags)(?=.*group-name)', re.IGNORECASE)
        pattern_string = re.compile(r'Chuyên môn', re.IGNORECASE)
        expertise_tag = soup.find('div', class_=pattern_class, string=pattern_string)
        if expertise_tag and expertise_tag.parent:
            expertise_list = expertise_tag.parent.find('div', class_=re.compile(r'group-list-tag-scroll'))
            if expertise_list:
                a_tags = expertise_list.find_all('a')
                tags_list = [a.get_text(strip=True) for a in a_tags if a.get_text(strip=True)]
                if tags_list:
                    return ", ".join(tags_list).replace('Chuyên môn', '').strip()
    except Exception: pass
    return None

def get_job_description_2(soup): return extract_paragraph_content_2(soup, "Mô tả công việc")
def get_requirements_2(soup): return extract_paragraph_content_2(soup, "Yêu cầu ứng viên")
def get_benefits_2(soup): return extract_paragraph_content_2(soup, "Quyền lợi được hưởng")



def human_scroll(driver):
    """Mô phỏng cuộn trang chậm như người thật"""
    try:
        total_height = int(driver.execute_script("return document.body.scrollHeight"))
        for i in range(1, total_height, random.randint(300, 700)):
            driver.execute_script(f"window.scrollTo(0, {i});")
            time.sleep(random.uniform(0.1, 0.4))
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(random.uniform(1.5, 2.5))
    except Exception as e:
        logging.error(f"Lỗi khi scroll: {e}")

# ── 5. VÒNG LẶP CHÍNH ────────────────────────────────────────────────────────────

def main():
    options = uc.ChromeOptions()
    prefs = {
        "credentials_enable_service": False,
        "profile.password_manager_enabled": False,
        "profile.default_content_setting_values.notifications": 2
    }
    options.add_experimental_option("prefs", prefs)
    
    current_dir = os.path.dirname(os.path.abspath(__file__)) if '__file__' in globals() else os.getcwd()
    profile_dir = os.path.join(current_dir, "topcv_profile")
    options.add_argument(f"--user-data-dir={profile_dir}")
    
    driver = uc.Chrome(options=options, version_main=140)
    driver.set_window_size(900, 1080)
    driver.set_window_position(900, 0)
    
    csv_columns = [
        "index", "job_link", "keyword", "title", "company_name", "location", "salary", 
        "date_posted", "deadline_date", "company_field", "job_type", 
        "job_level", "experience", "education", "hire_number", 
        "job_expertise", "description", "requirements", "benefits"
    ]


    # ── TẠO FILE CSV & CHECK TRÙNG LẶP DATA ──────────────────────────────────
    
    global_index = 1
    scraped_links = set()
    
    if os.path.exists(OUTPUT_CSV):
        try:
            with open(OUTPUT_CSV, mode="r", encoding="utf-8-sig") as file:
                reader = csv.DictReader(file)
                for row in reader:
                    link = row.get("job_link")
                    if link:
                        scraped_links.add(link)
                    try:
                        idx = int(row.get("index", 0))
                        if idx >= global_index:
                            global_index = idx + 1
                    except ValueError:
                        pass
            logging.info(f"Đã tìm thấy file CSV cũ. Bắt đầu nối thêm từ index {global_index}. Đã có {len(scraped_links)} job được cào.")
            print(f"Đã quét được {len(scraped_links)} job từ file cũ. Bắt đầu nối thêm từ index {global_index}.")
        except Exception as e:
            logging.error(f"Lỗi khi đọc file CSV cũ: {e}")
    else:
        try:
            with open(OUTPUT_CSV, mode="w", newline="", encoding="utf-8-sig") as file:
                writer = csv.DictWriter(file, fieldnames=csv_columns)
                writer.writeheader()
        except IOError:
            logging.error("Lỗi khi tạo file CSV")
            print("Lỗi khi tạo file CSV")
            driver.quit()
            return
            
    # ── CRAWL JOB CHI TIẾT ────────────────────────────────────────────────────
    
    for raw_keyword in KEYWORDS:
        formatted_keyword = raw_keyword.lower().replace(' ', '-')
        
        logging.info(f"==> BẮT ĐẦU CÀO KEYWORD: {raw_keyword} (URL: {formatted_keyword})")
        print(f"\n{'='*60}")
        print(f"BẮT ĐẦU QUÉT KEYWORD: {raw_keyword.upper()}")
        print(f"{'='*60}\n")
        
        # Xem trang 1 để lấy tổng số trang
        first_page_url = BASE_URL_TEMPLATE.format(keyword=formatted_keyword, page=1)
        driver.get(first_page_url)
        time.sleep(3)
        soup_page_1 = BeautifulSoup(driver.page_source, 'html.parser')
        actual_total_pages = get_total_pages(soup_page_1)
        
        pages_to_crawl = min(actual_total_pages, MAX_PAGES)
        print(f"[*] Từ khóa '{raw_keyword}' cào {pages_to_crawl} trang (Tổng: {actual_total_pages}).")
        
        for page in range(1, pages_to_crawl + 1):
            logging.info(f"keyword '{raw_keyword}' - Cào page {page} ===")
            print(f"keyword '{raw_keyword}' - Cào page {page} ===")
            
            target_url = BASE_URL_TEMPLATE.format(keyword=formatted_keyword, page=page)
            driver.get(target_url)
            time.sleep(random.uniform(3, 5))
            
            # Cuộn trang mượt mà như người thật
            human_scroll(driver)
                
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            job_link_date_dict = get_job_links_and_dates(soup)
            links = list(job_link_date_dict.keys())
            
            if not links:
                logging.info(f"Không tìm thấy job nào ở trang {page} cho từ khóa '{raw_keyword}'. Dừng cào từ khóa này.")
                print(f"\n[INFO] Hết job cho từ khóa '{raw_keyword}' tại trang {page}. Chuyển sang từ khóa tiếp theo.\n")
                break
                
            logging.info(f"Từ khóa '{raw_keyword}' | Trang {page} tìm thấy {len(links)} job links.")
            print(f"Từ khóa '{raw_keyword}' | Trang {page} tìm thấy {len(links)} job links.")
            
            for i, job_link in enumerate(links):
                if job_link in scraped_links:
                    logging.info(f"Bỏ qua job đã cào: {job_link}")
                    print(f"Bỏ qua job đã cào: {job_link}")
                    continue
                    
                logging.info(f"Đang cào job {i+1}/{len(links)} (page {page}): {job_link}")
                print(f"Đang cào job {i+1}/{len(links)} (page {page}): {job_link}")
                
                try:
                    if random.random() < 0.05:
                        logging.info("Nghỉ giải lao chống bot...")
                        time.sleep(random.uniform(10, 15))
                    
                    driver.get(job_link)
                    time.sleep(random.uniform(3, 6))
                    human_scroll(driver)
                    
                    new_soup = BeautifulSoup(driver.page_source, 'html.parser')
                    date_posted = job_link_date_dict.get(job_link)
                    
                    if "https://www.topcv.vn/brand/" in job_link:
                        # KIỂM TRA BOT CHO LINK BRAND
                        job_title = get_title_1(new_soup) or get_title_2(new_soup)
                        if not job_title:
                            logging.warning(f"Có thể đụng bot ở link Brand: {job_link}. Nghỉ ngơi 3 phút...")
                            print(f"🤖 [Bot Check] Trang không load được Title (Brand). Cho code đi ngủ 3 phút...")
                            time.sleep(180)
                            driver.refresh()
                            time.sleep(random.uniform(5, 8))
                            new_soup = BeautifulSoup(driver.page_source, 'html.parser')

                        company_tag = new_soup.find('h1', class_="title")
                        if company_tag:
                            # NHÓM 1
                            job_data = {
                                "index":            global_index,
                                "job_link":         job_link,
                                "keyword":          raw_keyword,
                                "title":            get_title_1(new_soup),
                                "company_name":     get_company_1(new_soup),
                                "location":         get_location_1(new_soup),
                                "salary":           get_salary_1(new_soup),
                                "date_posted":      date_posted,
                                "deadline_date":    get_job_deadline_1(new_soup),
                                "company_field":    None,
                                "job_type":         get_job_type_1(new_soup),
                                "job_level":        get_level_1(new_soup),
                                "experience":       get_years_experience_1(new_soup),
                                "education":        get_education_level_1(new_soup),
                                "hire_number":      get_hire_number_1(new_soup),
                                "job_expertise":    get_expertise_1(new_soup),
                                "description":      get_job_description_1(new_soup),
                                "requirements":     get_requirements_1(new_soup),
                                "benefits":         get_benefits_1(new_soup)
                            }
                        else:
                            # NHÓM 2
                            job_data = {
                                "index":            global_index,
                                "job_link":         job_link,
                                "keyword":          raw_keyword,
                                "title":            get_title_2(new_soup),
                                "company_name":     get_company_2(new_soup),
                                "location":         get_location_2(new_soup),
                                "salary":           get_salary_2(new_soup),
                                "date_posted":      date_posted,
                                "deadline_date":    get_job_deadline_2(new_soup),
                                "company_field":    None,
                                "job_type":         get_job_type_2(new_soup),
                                "job_level":        get_level_2(new_soup),
                                "experience":       get_years_experience_2(new_soup),
                                "education":        get_education_level_2(new_soup),
                                "hire_number":      get_hire_number_2(new_soup),
                                "job_expertise":    get_expertise_2(new_soup),
                                "description":      get_job_description_2(new_soup),
                                "requirements":     get_requirements_2(new_soup),
                                "benefits":         get_benefits_2(new_soup)
                            }
                    else:
                        # NHÓM 0 (Bình thường)
                        job_title = get_title(new_soup)
                        if not job_title:
                            logging.warning(f"Có thể đụng bot ở link: {job_link}. Nghỉ ngơi 3 phút...")
                            print(f"🤖 [Bot Check] Trang không load được Title. Cho code đi ngủ 3 phút...")
                            time.sleep(180)
                            driver.refresh()
                            time.sleep(random.uniform(5, 8))
                            new_soup = BeautifulSoup(driver.page_source, 'html.parser')
                            job_title = get_title(new_soup)
                            
                        all_info = job_general_info(new_soup)
                        job_data = {
                            "index":            global_index,
                            "job_link":         job_link,
                            "keyword":          raw_keyword,
                            "title":            job_title,
                            "company_name":     get_company(new_soup),
                            "location":         get_location(new_soup),
                            "salary":           get_salary(new_soup),
                            "date_posted":      date_posted,
                            "deadline_date":    get_deadline_date(new_soup),
                            "company_field":    get_field(new_soup),
                            "job_type":         all_info.get('Hình thức làm việc'),
                            "job_level":        all_info.get('Cấp bậc'),
                            "experience":       get_experience(new_soup),
                            "education":        all_info.get('Học vấn'),
                            "hire_number":      all_info.get('Số lượng tuyển'),
                            "job_expertise":    get_job_expertise(new_soup),
                            "description":      get_job_description(new_soup),
                            "requirements":     get_job_requirements(new_soup),
                            "benefits":         get_benefits(new_soup)
                        }
                    
                    try:
                        with open(OUTPUT_CSV, mode="a", newline="", encoding="utf-8-sig") as file:
                            writer = csv.DictWriter(file, fieldnames=csv_columns)
                            writer.writerow(job_data)
                        scraped_links.add(job_link)
                    except IOError:
                        logging.error("Lỗi khi ghi dòng mới vào file CSV")
                    
                    global_index += 1
                    
                except Exception as e:
                    logging.error(f"Lỗi khi cào job {job_link}: {e}")
                    continue

    driver.quit()
    print("Hoàn thành quá trình cào dữ liệu TopCV!")

# ── 6. ENTRY POINT ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    main()
