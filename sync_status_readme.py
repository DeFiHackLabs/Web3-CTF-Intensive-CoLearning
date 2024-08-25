import os
import subprocess
import re
import requests
from datetime import datetime, timedelta
import pytz
import logging

# Constants
START_DATE = datetime.fromisoformat(os.environ.get(
    'START_DATE', '2024-06-24T00:00:00+00:00')).replace(tzinfo=pytz.UTC)
END_DATE = datetime.fromisoformat(os.environ.get(
    'END_DATE', '2024-07-14T23:59:59+00:00')).replace(tzinfo=pytz.UTC)
DEFAULT_TIMEZONE = 'Asia/Shanghai'
FILE_SUFFIX = os.environ.get('FILE_SUFFIX', '_EICL1st.md')
README_FILE = 'README.md'
FIELD_NAME = os.environ.get('FIELD_NAME', 'EICL1st· Name')
Content_START_MARKER = "<!-- Content_START -->"
Content_END_MARKER = "<!-- Content_END -->"
TABLE_START_MARKER = "<!-- START_COMMIT_TABLE -->"
TABLE_END_MARKER = "<!-- END_COMMIT_TABLE -->"
GITHUB_REPOSITORY_OWNER = os.environ.get('GITHUB_REPOSITORY_OWNER')
GITHUB_REPOSITORY = os.environ.get('GITHUB_REPOSITORY')

# Configure logging
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')


def print_env():
    print(f"""
            START_DATE: {START_DATE}
            END_DATE: {END_DATE}
            DEFAULT_TIMEZONE: {DEFAULT_TIMEZONE}
            FILE_SUFFIX: {FILE_SUFFIX}
            README_FILE: {README_FILE}
            FIELD_NAME: {FIELD_NAME}
            Content_START_MARKER: {Content_START_MARKER}
            Content_END_MARKER: {Content_END_MARKER}
            TABLE_START_MARKER: {TABLE_START_MARKER}
            TABLE_END_MARKER: {TABLE_END_MARKER}
            """)


def print_variables(*args, **kwargs):
    def format_value(value):
        if isinstance(value, str) and ('\n' in value or '\r' in value):
            return f'"""\n{value}\n"""'
        return repr(value)

    variables = {}

    # 处理位置参数
    for arg in args:
        if isinstance(arg, dict):
            variables.update(arg)
        else:
            variables[arg] = eval(arg)

    # 处理关键字参数
    variables.update(kwargs)

    # 打印变量
    for name, value in variables.items():
        print(f"{name}: {format_value(value)}")


def get_date_range():
    return [START_DATE + timedelta(days=x) for x in range((END_DATE - START_DATE).days + 1)]


def get_user_timezone(file_content):
    yaml_match = re.search(r'---\s*\ntimezone:\s*(\S+)\s*\n---', file_content)
    if yaml_match:
        try:
            return pytz.timezone(yaml_match.group(1))
        except pytz.exceptions.UnknownTimeZoneError:
            logging.warning(
                f"Unknown timezone: {yaml_match.group(1)}. Using default {DEFAULT_TIMEZONE}.")
    return pytz.timezone(DEFAULT_TIMEZONE)


def extract_content_between_markers(file_content):
    start_index = file_content.find(Content_START_MARKER)
    end_index = file_content.find(Content_END_MARKER)
    if start_index == -1 or end_index == -1:
        logging.warning("Content_START_MARKER markers not found in the file")
        return ""
    return file_content[start_index + len(Content_START_MARKER):end_index].strip()


def find_date_in_content(content, local_date):
    date_patterns = [
        r'###\s*' + local_date.strftime("%Y.%m.%d"),
        r'###\s*' + local_date.strftime("%Y.%m.%d").replace('.0', '.'),
        r'###\s*' +
        local_date.strftime("%m.%d").lstrip('0').replace('.0', '.'),
        r'###\s*' + local_date.strftime("%Y/%m/%d"),
        r'###\s*' +
        local_date.strftime("%m/%d").lstrip('0').replace('/0', '/'),
        r'###\s*' + local_date.strftime("%m.%d").zfill(5)
    ]
    combined_pattern = '|'.join(date_patterns)
    return re.search(combined_pattern, content)


def get_content_for_date(content, start_pos):
    next_date_pattern = r'###\s*(\d{4}\.)?(\d{1,2}[\.\/]\d{1,2})'
    next_date_match = re.search(next_date_pattern, content[start_pos:])
    if next_date_match:
        return content[start_pos:start_pos + next_date_match.start()]
    return content[start_pos:]


def check_md_content(file_content, date, user_tz):
    try:
        content = extract_content_between_markers(file_content)
        local_date = date.astimezone(user_tz).replace(
            hour=0, minute=0, second=0, microsecond=0)
        current_date_match = find_date_in_content(content, local_date)

        if not current_date_match:
            logging.info(
                f"No match found for date {local_date.strftime('%Y-%m-%d')}")
            return False

        date_content = get_content_for_date(content, current_date_match.end())
        date_content = re.sub(r'\s', '', date_content)
        logging.info(
            f"Content length for {local_date.strftime('%Y-%m-%d')}: {len(date_content)}")
        return len(date_content) > 10
    except Exception as e:
        logging.error(f"Error in check_md_content: {str(e)}")
        return False


def get_user_study_status(nickname):
    user_status = {}
    file_name = f"{nickname}{FILE_SUFFIX}"
    try:
        with open(file_name, 'r', encoding='utf-8') as file:
            file_content = file.read()
        user_tz = get_user_timezone(file_content)
        logging.info(
            f"File content length for {nickname}: {len(file_content)} user_tz: {user_tz}")
        current_date = datetime.now(user_tz).replace(
            hour=0, minute=0, second=0, microsecond=0)  # - timedelta(days=1)

        for date in get_date_range():
            local_date = date.astimezone(user_tz).replace(
                hour=0, minute=0, second=0, microsecond=0)

            if date.day == current_date.day:
                user_status[date] = "✅" if check_md_content(
                    file_content, date, pytz.UTC) else " "
            elif date > current_date:
                user_status[date] = " "
            else:
                user_status[date] = "✅" if check_md_content(
                    file_content, date, pytz.UTC) else "⭕️"

        logging.info(f"Successfully processed file for user: {nickname}")
    except FileNotFoundError:
        logging.error(f"Error: Could not find file {file_name}")
        user_status = {date: "⭕️" for date in get_date_range()}
    except Exception as e:
        logging.error(
            f"Unexpected error processing file for {nickname}: {str(e)}")
        user_status = {date: "⭕️" for date in get_date_range()}
    return user_status


def check_weekly_status(user_status, date, user_tz):
    try:
        local_date = date.astimezone(user_tz).replace(
            hour=0, minute=0, second=0, microsecond=0)
        week_start = (local_date - timedelta(days=local_date.weekday()))
        week_dates = [week_start + timedelta(days=x) for x in range(7)]
        current_date = datetime.now(user_tz).replace(
            hour=0, minute=0, second=0, microsecond=0)
        week_dates = [d for d in week_dates if d.astimezone(pytz.UTC).date() in [
            date.date() for date in get_date_range()] and d <= min(local_date, current_date)]

        missing_days = sum(1 for d in week_dates if user_status.get(datetime.combine(
            d.astimezone(pytz.UTC).date(), datetime.min.time()).replace(tzinfo=pytz.UTC), "⭕️") == "⭕️")

        if local_date == current_date and missing_days > 2:
            return "❌"
        elif local_date < current_date and missing_days > 2:
            return "❌"
        elif local_date > current_date:
            return " "
        else:
            return user_status.get(datetime.combine(date.date(), datetime.min.time()).replace(tzinfo=pytz.UTC), "⭕️")
    except Exception as e:
        logging.error(f"Error in check_weekly_status: {str(e)}")
        return "⭕️"


def get_all_user_files():
    return [f[:-len(FILE_SUFFIX)] for f in os.listdir('.')
            if f.endswith(FILE_SUFFIX) and not f.startswith('Template')]


def update_readme(content):
    try:
        start_index = content.find(TABLE_START_MARKER)
        end_index = content.find(TABLE_END_MARKER)
        if start_index == -1 or end_index == -1:
            logging.error(
                "Error: Couldn't find the table markers in README.md")
            return content

        new_table = [
            f'{TABLE_START_MARKER}\n',
            f'| {FIELD_NAME} | ' +
            ' | '.join(date.strftime("%m.%d").lstrip('0')
                       for date in get_date_range()) + ' |\n',
            '| ------------- | ' +
            ' | '.join(['----' for _ in get_date_range()]) + ' |\n'
        ]

        existing_users = set()
        table_rows = content[start_index +
                             len(TABLE_START_MARKER):end_index].strip().split('\n')[2:]

        for row in table_rows:
            match = re.match(r'\|\s*([^|]+)\s*\|', row)
            if match:
                display_name = match.group(1).strip()
                if display_name:  # 检查 display_name 是否为非空
                    existing_users.add(display_name)
                    new_table.append(generate_user_row(display_name))
                else:
                    logging.warning(
                        f"Skipping empty display name in row: {row}")
            else:
                logging.warning(f"Skipping invalid row: {row}")

        new_users = set(get_all_user_files()) - existing_users
        for user in new_users:
            if user.strip():  # 确保用户名不是空的或只包含空格
                new_table.append(generate_user_row(user))
                logging.info(f"Added new user: {user}")
            else:
                logging.warning(f"Skipping empty user: '{user}'")
        new_table.append(f'{TABLE_END_MARKER}\n')
        return content[:start_index] + ''.join(new_table) + content[end_index + len(TABLE_END_MARKER):]
    except Exception as e:
        logging.error(f"Error in update_readme: {str(e)}")
        return content


def generate_user_row(user):
    user_status = get_user_study_status(user)
    with open(f"{user}{FILE_SUFFIX}", 'r', encoding='utf-8') as file:
        file_content = file.read()
    user_tz = get_user_timezone(file_content)
    new_row = f"| {user} |"
    is_eliminated = False
    absent_count = 0
    current_week = None

    user_current_day = datetime.now(user_tz).replace(
        hour=0, minute=0, second=0, microsecond=0)
    for date in get_date_range():
        # 获取用户时区和当地时间进行比较，如果用户打卡时间大于当地时间，则不显示- timedelta(days=1)
        user_datetime = date.astimezone(pytz.UTC).replace(
            hour=0, minute=0, second=0, microsecond=0)
        if is_eliminated or (user_datetime > user_current_day and user_datetime.day > user_current_day.day):
            new_row += " |"
        else:
            user_date = user_datetime
            # 检查是否是新的一周
            week = user_date.isocalendar()[1]  # 获取ISO日历周数
            if week != current_week:
                current_week = week
                absent_count = 0  # 重置缺勤计数

            status = user_status.get(user_date, "")

            if status == "⭕️":
                absent_count += 1
                if absent_count > 2:
                    is_eliminated = True
                    new_row += " ❌ |"
                else:
                    new_row += " ⭕️ |"
            else:
                new_row += f" {status} |"

    return new_row + '\n'


def get_repo_info():
    if 'GITHUB_REPOSITORY' in os.environ:
        # 在GitHub Actions环境中
        full_repo = os.environ['GITHUB_REPOSITORY']
        owner, repo = full_repo.split('/')
    else:
        # 在本地环境中
        try:
            remote_url = subprocess.check_output(
                ['git', 'config', '--get', 'remote.origin.url']).decode('utf-8').strip()
            if remote_url.startswith('https://github.com/'):
                owner, repo = remote_url.split('/')[-2:]
            elif remote_url.startswith('git@github.com:'):
                owner, repo = remote_url.split(':')[-1].split('/')
            else:
                raise ValueError("Unsupported remote URL format")
            repo = re.sub(r'\.git$', '', repo)
        except subprocess.CalledProcessError:
            logging.error(
                "Failed to get repository information from git config")
            return None, None
    return owner, repo


def get_fork_count():
    owner, repo = get_repo_info()
    if not owner or not repo:
        logging.error("Failed to get repository information")
        return None

    api_url = f"https://api.github.com/repos/{owner}/{repo}"

    try:
        response = requests.get(api_url)
        response.raise_for_status()
        repo_data = response.json()
        return repo_data['forks_count']
    except requests.RequestException as e:
        logging.error(f"Error fetching fork count: {e}")
        return None


def calculate_statistics(content):
    start_index = content.find(TABLE_START_MARKER)
    end_index = content.find(TABLE_END_MARKER)
    if start_index == -1 or end_index == -1:
        logging.error("Error: Couldn't find the table markers in README.md")
        return None

    table_content = content[start_index +
                            len(TABLE_START_MARKER):end_index].strip()
    rows = table_content.split('\n')[2:]  # Skip header and separator rows

    total_participants = len(rows)
    eliminated_participants = 0
    completed_participants = 0
    perfect_attendance_users = []

    for row in rows:
        user_name = row.split('|')[1].strip()
        # Exclude first and last empty elements
        statuses = [status.strip() for status in row.split('|')[2:-1]]

        if '❌' in statuses:
            eliminated_participants += 1
        elif all(status == '✅' for status in statuses):
            completed_participants += 1
            perfect_attendance_users.append(user_name)
        elif all(status in ['✅', '⭕️', ' '] for status in statuses):
            completed_participants += 1

    elimination_rate = (eliminated_participants /
                        total_participants) * 100 if total_participants > 0 else 0
    fork_count = get_fork_count()

    return {
        'total_participants': total_participants,
        'completed_participants': completed_participants,
        'eliminated_participants': eliminated_participants,
        'elimination_rate': elimination_rate,
        'fork_count': fork_count,
        'perfect_attendance_users': perfect_attendance_users
    }


def main():
    try:
        print_variables(
            'START_DATE', 'END_DATE', 'DEFAULT_TIMEZONE',
            GITHUB_REPOSITORY_OWNER=GITHUB_REPOSITORY,
            GITHUB_REPOSITORY=GITHUB_REPOSITORY,
            FILE_SUFFIX=FILE_SUFFIX,
            README_FILE=README_FILE,
            FIELD_NAME=FIELD_NAME,
            Content_START_MARKER=Content_START_MARKER,
            Content_END_MARKER=Content_END_MARKER,
            TABLE_START_MARKER=TABLE_START_MARKER,
            TABLE_END_MARKER=TABLE_END_MARKER
        )
        with open(README_FILE, 'r', encoding='utf-8') as file:
            content = file.read()
        new_content = update_readme(content)
        current_date = datetime.now(pytz.UTC)
        if current_date > END_DATE:
            stats = calculate_statistics(new_content)
            if stats:
                stats_content = f"\n\n## 统计数据\n\n"
                stats_content += f"- 总参与人数: {stats['total_participants']}\n"
                stats_content += f"- 完成人数: {stats['completed_participants']}\n"
                stats_content += f"- 全勤用户: {', '.join(stats['perfect_attendance_users'])}\n"
                stats_content += f"- 淘汰人数: {stats['eliminated_participants']}\n"
                stats_content += f"- 淘汰率: {stats['elimination_rate']:.2f}%\n"
                stats_content += f"- Fork人数: {stats['fork_count']}\n"
            # 将统计数据添加到文件末尾
            # 在<!-- END_COMMIT_TABLE -->标记后插入统计数据
                stats_start = new_content.find(
                    "<!-- STATISTICALDATA_START -->")
                stats_end = new_content.find("<!-- STATISTICALDATA_END -->")

                if stats_start != -1 and stats_end != -1:
                    # Replace existing statistical data
                    new_content = new_content[:stats_start] + "<!-- STATISTICALDATA_START -->\n" + stats_content + \
                        "<!-- STATISTICALDATA_END -->" + \
                        new_content[stats_end +
                                    len("<!-- STATISTICALDATA_END -->"):]
                else:
                    # Add new statistical data after <!-- END_COMMIT_TABLE -->
                    end_table_marker = "<!-- END_COMMIT_TABLE -->"
                    end_table_index = new_content.find(end_table_marker)
                    if end_table_index != -1:
                        insert_position = end_table_index + \
                            len(end_table_marker)
                        new_content = new_content[:insert_position] + "\n\n<!-- STATISTICALDATA_START -->\n" + \
                            stats_content + "<!-- STATISTICALDATA_END -->" + \
                            new_content[insert_position:]
                    else:
                        logging.warning(
                            "<!-- END_COMMIT_TABLE --> marker not found. Appending stats to the end.")
                        new_content += "\n\n<!-- STATISTICALDATA_START -->\n" + \
                            stats_content + "<!-- STATISTICALDATA_END -->"
        with open(README_FILE, 'w', encoding='utf-8') as file:
            file.write(new_content)
        logging.info("README.md has been successfully updated.")
    except Exception as e:
        logging.error(f"An error occurred in main function: {str(e)}")


if __name__ == "__main__":
    main()
