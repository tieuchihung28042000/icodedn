# Hướng dẫn sử dụng Admin Interface - VNOJ

## Mục lục

1. [Tổng quan](#tổng-quan)
2. [Cấu trúc Admin Pages](#cấu-trúc-admin-pages)
   - 2.1 [Quản lý người dùng (Users & Profiles)](#1-quản-lý-người-dùng-users--profiles)
   - 2.2 [Quản lý bài tập (Problems)](#2-quản-lý-bài-tập-problems)
   - 2.3 [Quản lý cuộc thi (Contests)](#3-quản-lý-cuộc-thi-contests)
   - 2.4 [Quản lý submissions (Bài nộp)](#4-quản-lý-submissions-bài-nộp)
   - 2.5 [Quản lý tổ chức (Organizations)](#5-quản-lý-tổ-chức-organizations)
   - 2.6 [Quản lý runtime (Runtime Environment)](#6-quản-lý-runtime-runtime-environment)
   - 2.7 [Quản lý tags](#7-quản-lý-tags)
   - 2.8 [Quản lý nội dung (Content Management)](#8-quản-lý-nội-dung-content-management)
   - 2.9 [Quản lý hệ thống (System Management)](#9-quản-lý-hệ-thống-system-management)
3. [Hệ thống phân quyền](#hệ-thống-phân-quyền)
4. [Hướng dẫn sử dụng chi tiết với ví dụ](#hướng-dẫn-sử-dụng-chi-tiết-với-ví-dụ)
5. [Ví dụ Mock Data cụ thể](#ví-dụ-mock-data-cụ-thể)
6. [Workflow thực tế](#workflow-thực-tế)
7. [Troubleshooting thường gặp](#troubleshooting-thường-gặp)
8. [Best Practices](#best-practices)

## Tổng quan

Admin interface của VNOJ được xây dựng trên Django Admin với nhiều tùy chỉnh để quản lý hệ thống online judge. Hệ thống bao gồm các module chính để quản lý bài tập, cuộc thi, người dùng, tổ chức và nhiều chức năng khác.

### Đặc điểm nổi bật:
- **Giao diện thân thiện**: Tùy chỉnh từ Django Admin với UX tốt hơn
- **Phân quyền chi tiết**: Hệ thống permissions phức tạp cho từng chức năng
- **Inline editing**: Chỉnh sửa dữ liệu liên quan trực tiếp
- **Batch operations**: Thực hiện thao tác hàng loạt
- **Rich text editor**: Hỗ trợ Markdown và MathJax
- **Audit trail**: Theo dõi mọi thay đổi qua log entries

## Cấu trúc Admin Pages

### 1. Quản lý người dùng (Users & Profiles)

#### 1.1 Users (Người dùng)
- **Đường dẫn**: `/admin/auth/user/`
- **Chức năng**: Quản lý tài khoản người dùng cơ bản
- **Quyền hạn**: Chỉ superuser có thể truy cập
- **Tính năng**:
  - Tạo/sửa/xóa tài khoản
  - Quản lý quyền hạn (permissions)
  - Quản lý nhóm (groups)
  - Đặt lại mật khẩu

#### 1.2 Profiles (Hồ sơ người dùng)
- **Đường dẫn**: `/admin/judge/profile/`
- **Chức năng**: Quản lý thông tin chi tiết người dùng
- **Quyền hạn**: Quản trị viên có thể xem và chỉnh sửa
- **Tính năng**:
  - Quản lý thông tin cá nhân (timezone, ngôn ngữ, theme)
  - Quản lý điểm số và rating
  - Quản lý tổ chức (organizations)
  - Quản lý badges và display rank
  - Tính năng ban/mute người dùng
  - Quản lý TOTP (2FA)
  - Quản lý WebAuthn credentials
  - Tính lại điểm số (recalculate points)

**Các trường quan trọng**:
- `display_rank`: Hiển thị rank người dùng
- `vnoj_points`: Điểm VNOJ
- `rating`: Rating hiện tại
- `timezone`: Múi giờ
- `ban_reason`: Lý do ban (nếu có)
- `is_unlisted`: Ẩn khỏi ranking
- `current_contest`: Cuộc thi hiện tại đang tham gia

### 2. Quản lý bài tập (Problems)

#### 2.1 Problems (Bài tập)
- **Đường dẫn**: `/admin/judge/problem/`
- **Chức năng**: Quản lý bài tập
- **Quyền hạn**: Tác giả, curator hoặc admin có thể chỉnh sửa
- **Tính năng**:
  - Tạo/sửa/xóa bài tập
  - Quản lý đề bài (statement)
  - Quản lý test cases
  - Quản lý giới hạn thời gian/bộ nhớ
  - Quản lý ngôn ngữ được phép
  - Quản lý quyền truy cập (public/private)
  - Quản lý tổ chức riêng tư
  - Quản lý solutions
  - Quản lý translations

**Inline Models**:
- `LanguageLimit`: Giới hạn riêng cho từng ngôn ngữ
- `ProblemClarification`: Làm rõ bài tập
- `ProblemSolution`: Lời giải mẫu
- `ProblemTranslation`: Bản dịch

**Quyền hạn đặc biệt**:
- `see_private_problem`: Xem bài tập riêng tư
- `edit_own_problem`: Chỉnh sửa bài tập của mình
- `edit_all_problem`: Chỉnh sửa tất cả bài tập
- `change_public_visibility`: Thay đổi trạng thái public
- `problem_full_markup`: Sử dụng full markup

#### 2.2 Problem Groups (Nhóm bài tập)
- **Đường dẫn**: `/admin/judge/problemgroup/`
- **Chức năng**: Quản lý nhóm bài tập
- **Trường**: `name`, `full_name`

#### 2.3 Problem Types (Loại bài tập)
- **Đường dẫn**: `/admin/judge/problemtype/`
- **Chức năng**: Quản lý loại bài tập
- **Trường**: `name`, `full_name`

### 3. Quản lý cuộc thi (Contests)

#### 3.1 Contests (Cuộc thi)
- **Đường dẫn**: `/admin/judge/contest/`
- **Chức năng**: Quản lý cuộc thi
- **Quyền hạn**: Tác giả, curator hoặc admin có thể chỉnh sửa
- **Tính năng**:
  - Tạo/sửa/xóa cuộc thi
  - Quản lý thời gian (start_time, end_time)
  - Quản lý format cuộc thi
  - Quản lý quyền truy cập (public/private)
  - Quản lý rating
  - Quản lý scoreboard
  - Quản lý announcements
  - Quản lý problems trong cuộc thi

**Inline Models**:
- `ContestProblem`: Bài tập trong cuộc thi
- `ContestAnnouncement`: Thông báo cuộc thi

**Quyền hạn đặc biệt**:
- `edit_own_contest`: Chỉnh sửa cuộc thi của mình
- `edit_all_contest`: Chỉnh sửa tất cả cuộc thi
- `create_private_contest`: Tạo cuộc thi riêng tư
- `contest_rating`: Quản lý rating cuộc thi
- `lock_contest`: Khóa cuộc thi

#### 3.2 Contest Participations (Tham gia cuộc thi)
- **Đường dẫn**: `/admin/judge/contestparticipation/`
- **Chức năng**: Quản lý việc tham gia cuộc thi
- **Tính năng**:
  - Xem danh sách người tham gia
  - Quản lý virtual participations
  - Quản lý disqualifications

#### 3.3 Contest Tags (Tags cuộc thi)
- **Đường dẫn**: `/admin/judge/contesttag/`
- **Chức năng**: Quản lý tags cho cuộc thi
- **Trường**: `name`, `color`, `description`

### 4. Quản lý submissions (Bài nộp)

#### 4.1 Submissions (Bài nộp)
- **Đường dẫn**: `/admin/judge/submission/`
- **Chức năng**: Quản lý bài nộp
- **Quyền hạn**: Quản trị viên và tác giả bài tập có thể rejudge
- **Tính năng**:
  - Xem chi tiết bài nộp
  - Rejudge bài nộp
  - Quản lý source code
  - Xem kết quả chi tiết

**Quyền hạn đặc biệt**:
- `rejudge_submission`: Rejudge bài nộp
- `rejudge_submission_lot`: Rejudge nhiều bài nộp cùng lúc

### 5. Quản lý tổ chức (Organizations)

#### 5.1 Organizations (Tổ chức)
- **Đường dẫn**: `/admin/judge/organization/`
- **Chức năng**: Quản lý tổ chức
- **Quyền hạn**: Admin tổ chức hoặc superuser có thể chỉnh sửa
- **Tính năng**:
  - Tạo/sửa/xóa tổ chức
  - Quản lý thành viên
  - Quản lý admins
  - Quản lý credits
  - Quản lý quyền truy cập (open/private)

**Quyền hạn đặc biệt**:
- `organization_admin`: Quản trị tổ chức
- `edit_all_organization`: Chỉnh sửa tất cả tổ chức
- `change_open_organization`: Thay đổi trạng thái open
- `spam_organization`: Tạo tổ chức không giới hạn

#### 5.2 Organization Requests (Yêu cầu tham gia tổ chức)
- **Đường dẫn**: `/admin/judge/organizationrequest/`
- **Chức năng**: Quản lý yêu cầu tham gia tổ chức
- **Trường**: `user`, `organization`, `state`, `time`

### 6. Quản lý runtime (Runtime Environment)

#### 6.1 Languages (Ngôn ngữ lập trình)
- **Đường dẫn**: `/admin/judge/language/`
- **Chức năng**: Quản lý ngôn ngữ lập trình
- **Tính năng**:
  - Thêm/sửa/xóa ngôn ngữ
  - Quản lý compiler settings
  - Quản lý template code
  - Quản lý file extensions

#### 6.2 Judges (Judge servers)
- **Đường dẫn**: `/admin/judge/judge/`
- **Chức năng**: Quản lý judge servers
- **Tính năng**:
  - Xem trạng thái judge
  - Disconnect/terminate judge
  - Quản lý authentication
  - Xem capabilities

### 7. Quản lý tags

#### 7.1 Tags (Tags)
- **Đường dẫn**: `/admin/judge/tag/`
- **Chức năng**: Quản lý tags cho bài tập
- **Trường**: `code`, `name`, `group`

#### 7.2 Tag Groups (Nhóm tags)
- **Đường dẫn**: `/admin/judge/taggroup/`
- **Chức năng**: Quản lý nhóm tags
- **Trường**: `code`, `name`

#### 7.3 Tag Problems (Tags của bài tập)
- **Đường dẫn**: `/admin/judge/tagproblem/`
- **Chức năng**: Quản lý việc gắn tags cho bài tập

### 8. Quản lý nội dung (Content Management)

#### 8.1 Blog Posts (Bài viết blog)
- **Đường dẫn**: `/admin/judge/blogpost/`
- **Chức năng**: Quản lý bài viết blog
- **Quyền hạn**: Tác giả hoặc admin có thể chỉnh sửa
- **Tính năng**:
  - Tạo/sửa/xóa bài viết
  - Quản lý quyền truy cập (public/private)
  - Quản lý tổ chức riêng tư
  - Quản lý sticky posts
  - Quản lý publish date

**Quyền hạn đặc biệt**:
- `edit_all_post`: Chỉnh sửa tất cả bài viết
- `edit_organization_post`: Chỉnh sửa bài viết tổ chức
- `mark_global_post`: Đánh dấu bài viết global
- `pin_post`: Pin bài viết

#### 8.2 Comments (Bình luận)
- **Đường dẫn**: `/admin/judge/comment/`
- **Chức năng**: Quản lý bình luận
- **Tính năng**:
  - Ẩn/hiện bình luận
  - Quản lý điểm số bình luận
  - Xem linked pages

#### 8.3 Navigation Bar (Thanh điều hướng)
- **Đường dẫn**: `/admin/judge/navigationbar/`
- **Chức năng**: Quản lý thanh điều hướng
- **Tính năng**:
  - Thêm/sửa/xóa menu items
  - Quản lý thứ tự (drag & drop)
  - Quản lý hierarchy (parent/child)

#### 8.4 Flat Pages (Trang tĩnh)
- **Đường dẫn**: `/admin/flatpages/flatpage/`
- **Chức năng**: Quản lý trang tĩnh
- **Tính năng**:
  - Tạo/sửa/xóa trang tĩnh
  - Quản lý URL patterns
  - Quản lý nội dung

### 9. Quản lý hệ thống (System Management)

#### 9.1 Licenses (Giấy phép)
- **Đường dẫn**: `/admin/judge/license/`
- **Chức năng**: Quản lý giấy phép cho bài tập
- **Trường**: `key`, `name`, `link`, `display`, `icon`, `text`

#### 9.2 Tickets (Tickets hỗ trợ)
- **Đường dẫn**: `/admin/judge/ticket/`
- **Chức năng**: Quản lý tickets hỗ trợ
- **Tính năng**:
  - Xem/trả lời tickets
  - Assign tickets
  - Quản lý notes

#### 9.3 Badges (Huy hiệu)
- **Đường dẫn**: `/admin/judge/badge/`
- **Chức năng**: Quản lý huy hiệu người dùng

#### 9.4 Misc Config (Cấu hình khác)
- **Đường dẫn**: `/admin/judge/miscconfig/`
- **Chức năng**: Quản lý cấu hình hệ thống khác

#### 9.5 Log Entry (Nhật ký hệ thống)
- **Đường dẫn**: `/admin/admin/logentry/`
- **Chức năng**: Xem nhật ký thay đổi admin
- **Quyền hạn**: Chỉ superuser có thể xem

## Hệ thống phân quyền

### Quyền hạn cơ bản
- **Superuser**: Toàn quyền truy cập tất cả chức năng
- **Staff**: Truy cập admin interface nhưng bị giới hạn quyền
- **Normal User**: Không truy cập admin interface

### Quyền hạn đặc biệt cho Problems
- `see_private_problem`: Xem bài tập riêng tư
- `edit_own_problem`: Chỉnh sửa bài tập của mình
- `edit_all_problem`: Chỉnh sửa tất cả bài tập
- `change_public_visibility`: Thay đổi trạng thái public
- `problem_full_markup`: Sử dụng full markup

### Quyền hạn đặc biệt cho Contests
- `edit_own_contest`: Chỉnh sửa cuộc thi của mình
- `edit_all_contest`: Chỉnh sửa tất cả cuộc thi
- `create_private_contest`: Tạo cuộc thi riêng tư
- `contest_rating`: Quản lý rating cuộc thi
- `lock_contest`: Khóa cuộc thi

### Quyền hạn đặc biệt cho Organizations
- `organization_admin`: Quản trị tổ chức
- `edit_all_organization`: Chỉnh sửa tất cả tổ chức
- `change_open_organization`: Thay đổi trạng thái open
- `spam_organization`: Tạo tổ chức không giới hạn

### Quyền hạn đặc biệt cho Profiles
- `test_site`: Hiển thị tính năng development
- `totp`: Chỉnh sửa cài đặt TOTP
- `can_upload_image`: Upload ảnh trực tiếp
- `high_problem_timelimit`: Đặt giới hạn thời gian cao
- `long_contest_duration`: Đặt thời gian cuộc thi dài
- `create_mass_testcases`: Tạo nhiều test cases
- `ban_user`: Ban người dùng

### Quyền hạn đặc biệt cho Blog Posts
- `edit_all_post`: Chỉnh sửa tất cả bài viết
- `edit_organization_post`: Chỉnh sửa bài viết tổ chức
- `mark_global_post`: Đánh dấu bài viết global
- `pin_post`: Pin bài viết

### Quyền hạn đặc biệt cho Submissions
- `rejudge_submission`: Rejudge bài nộp
- `rejudge_submission_lot`: Rejudge nhiều bài nộp cùng lúc

## Hướng dẫn sử dụng chi tiết

### 1. Quản lý bài tập

#### Tạo bài tập mới
1. Truy cập `/admin/judge/problem/`
2. Click "Add Problem"
3. Điền thông tin cơ bản:
   - `code`: Mã bài tập (unique)
   - `name`: Tên bài tập
   - `authors`: Tác giả
   - `curators`: Người curator
   - `points`: Điểm số
4. Điền đề bài trong `description` (hỗ trợ Markdown)
5. Cấu hình giới hạn:
   - `time_limit`: Giới hạn thời gian (milliseconds)
   - `memory_limit`: Giới hạn bộ nhớ (KB)
6. Chọn ngôn ngữ được phép trong `allowed_languages`
7. Cấu hình quyền truy cập:
   - `is_public`: Công khai bài tập
   - `is_organization_private`: Riêng tư cho tổ chức
   - `organizations`: Chọn tổ chức (nếu riêng tư)

#### Quản lý test cases
1. **Truy cập trang test data**:
   - Từ admin: `/admin/judge/problem/` → Chọn bài tập → "Edit test data" link
   - Từ problem page: `/problem/<code>/` → "Edit test data" (nếu có quyền)
   - Trực tiếp: `/problem/<code>/test_data`
2. **Upload ZIP file chứa test cases**:
   - Tạo file ZIP chứa các file input/output
   - Các format được hỗ trợ:
     - **Themis**: `*.inp` và `*.out` (hoặc `*.in` và `*.out`)
     - **CMS**: `input.001`, `input.002` và `output.001`, `output.002`
     - **Polygon**: `1`, `2`, `3` và `1.a`, `2.a`, `3.a`
     - **DMOJ**: `*.in` và `*.out` với pattern linh hoạt
3. **Upload và auto-detect**:
   - Chọn file ZIP trong trường "Zipfile"
   - Hệ thống sẽ tự động detect format và fill test cases
   - Kiểm tra bảng test cases được tạo tự động
4. **Chỉnh sửa test cases thủ công**:
   - Thêm/xóa test cases bằng nút "+" và checkbox "Delete"
   - Cấu hình điểm số cho từng test case
   - Đánh dấu pretest nếu cần
5. **Apply** để lưu thay đổi

#### Quản lý solutions
1. Trong trang edit bài tập, sử dụng inline "Solutions"
2. Thêm lời giải mẫu với source code
3. Cấu hình quyền truy cập solution

### 2. Quản lý cuộc thi

#### Tạo cuộc thi mới
1. Truy cập `/admin/judge/contest/`
2. Click "Add Contest"
3. Điền thông tin cơ bản:
   - `key`: Mã cuộc thi (unique)
   - `name`: Tên cuộc thi
   - `authors`: Tác giả
   - `curators`: Người curator
4. Cấu hình thời gian:
   - `start_time`: Thời gian bắt đầu
   - `end_time`: Thời gian kết thúc
   - `time_limit`: Giới hạn thời gian (nếu có)
5. Cấu hình format:
   - `format_name`: Loại format (IOI, ICPC, etc.)
   - `format_config`: Cấu hình JSON
6. Cấu hình quyền truy cập:
   - `is_visible`: Hiển thị cuộc thi
   - `is_private`: Cuộc thi riêng tư
   - `access_code`: Mã truy cập (nếu có)

#### Thêm bài tập vào cuộc thi
1. Trong trang edit cuộc thi, sử dụng inline "Contest problems"
2. Chọn bài tập và cấu hình:
   - `order`: Thứ tự hiển thị
   - `points`: Điểm số (có thể khác với bài tập gốc)
   - `partial`: Cho phép điểm từng phần
   - `is_pretested`: Chỉ chạy pretest

#### Quản lý announcements
1. Sử dụng inline "Announcements" trong trang edit cuộc thi
2. Thêm thông báo với title và content
3. Cấu hình thời gian hiển thị

### 3. Quản lý người dùng

#### Quản lý profile người dùng
1. Truy cập `/admin/judge/profile/`
2. Tìm người dùng cần chỉnh sửa
3. Cấu hình thông tin:
   - `display_rank`: Rank hiển thị
   - `organizations`: Tổ chức tham gia
   - `timezone`: Múi giờ
   - `language`: Ngôn ngữ giao diện
   - `ace_theme`: Theme editor

#### Ban/mute người dùng
1. Trong trang edit profile
2. Điền `ban_reason` để ban người dùng
3. Tick `mute` để mute người dùng
4. Tick `is_unlisted` để ẩn khỏi ranking

#### Tính lại điểm số
1. Chọn người dùng cần tính lại điểm
2. Sử dụng action "Recalculate scores"
3. Hoặc "Recalculate contribution points" cho điểm đóng góp

### 4. Quản lý tổ chức

#### Tạo tổ chức mới
1. Truy cập `/admin/judge/organization/`
2. Click "Add Organization"
3. Điền thông tin:
   - `name`: Tên tổ chức
   - `slug`: URL slug (unique)
   - `short_name`: Tên ngắn
   - `admins`: Quản trị viên
   - `is_open`: Cho phép tự tham gia
   - `slots`: Số lượng thành viên tối đa

#### Quản lý thành viên
1. Thành viên tự tham gia (nếu `is_open = True`)
2. Hoặc admin thêm thành viên thông qua profile
3. Quản lý yêu cầu tham gia qua `/admin/judge/organizationrequest/`

### 5. Quản lý nội dung

#### Tạo blog post
1. Truy cập `/admin/judge/blogpost/`
2. Click "Add Blog post"
3. Điền thông tin:
   - `title`: Tiêu đề
   - `slug`: URL slug
   - `authors`: Tác giả
   - `content`: Nội dung (Markdown)
   - `visible`: Hiển thị
   - `sticky`: Ghim bài viết
   - `publish_on`: Thời gian xuất bản

#### Quản lý navigation
1. Truy cập `/admin/judge/navigationbar/`
2. Sử dụng drag & drop để sắp xếp menu
3. Cấu hình:
   - `key`: Mã menu item
   - `label`: Nhãn hiển thị
   - `path`: URL đích
   - `parent`: Menu cha (nếu có)

### 6. Quản lý hệ thống

#### Quản lý judge servers
1. Truy cập `/admin/judge/judge/`
2. Xem trạng thái online/offline
3. Sử dụng actions:
   - "Disconnect": Ngắt kết nối judge
   - "Terminate": Force terminate judge
   - "Disable": Vô hiệu hóa judge

#### Quản lý ngôn ngữ
1. Truy cập `/admin/judge/language/`
2. Thêm/sửa ngôn ngữ lập trình
3. Cấu hình:
   - `key`: Mã ngôn ngữ
   - `name`: Tên đầy đủ
   - `common_name`: Tên thông dụng
   - `ace`: Mode cho ACE editor
   - `template`: Template code mặc định

## Lưu ý quan trọng

### Bảo mật
- Chỉ cấp quyền admin cho những người đáng tin cậy
- Sử dụng 2FA (TOTP) cho tài khoản admin
- Thường xuyên kiểm tra log entries
- Backup database thường xuyên

### Performance
- Batch operations khi có thể (rejudge nhiều submissions)
- Sử dụng filters để giảm tải database
- Cẩn thận với cascading deletes

### Workflow
- Test trên staging environment trước khi deploy
- Sử dụng revisions để track changes
- Cẩn thận với public/private toggles
- Backup trước khi thực hiện thay đổi lớn

### Troubleshooting
- Kiểm tra log entries khi có lỗi
- Sử dụng Django shell cho debugging
- Kiểm tra permissions khi user không thể truy cập
- Kiểm tra judge status khi submissions bị stuck

## Hướng dẫn sử dụng chi tiết với ví dụ

### 1. Quản lý bài tập với ví dụ cụ thể

#### Ví dụ: Tạo bài tập "A+B Problem"
```
Thông tin cơ bản:
- Code: aplusb
- Name: A+B Problem
- Authors: admin
- Points: 100
- Time limit: 1000ms
- Memory limit: 65536KB

Đề bài:
Cho hai số nguyên A và B. Tính tổng A + B.

Input:
Dòng đầu tiên chứa hai số nguyên A và B (-10^9 ≤ A, B ≤ 10^9).

Output:
In ra tổng A + B.

Sample Input:
1 2

Sample Output:
3
```

#### Workflow tạo bài tập:
1. **Truy cập**: `/admin/judge/problem/add/`
2. **Điền form**:
   - Code: `aplusb`
   - Name: `A+B Problem`
   - Authors: Chọn từ dropdown
   - Points: `100`
   - Time limit: `1000` (ms)
   - Memory limit: `65536` (KB)
3. **Đề bài**: Sử dụng Markdown editor
4. **Cấu hình**: 
   - ✅ Is public
   - ✅ Allow judge
   - Languages: Chọn tất cả
5. **Save** → Tiếp tục upload test cases

#### Hướng dẫn upload test cases chi tiết:

**Bước 1: Chuẩn bị file test cases**
```
Tạo thư mục test_cases/ với cấu trúc:
aplusb_tests/
├── 1.inp        # Test case 1 input
├── 1.out        # Test case 1 output
├── 2.inp        # Test case 2 input
├── 2.out        # Test case 2 output
├── 3.inp        # Test case 3 input
└── 3.out        # Test case 3 output

Nội dung file:
- 1.inp: "1 2"
- 1.out: "3"
- 2.inp: "5 7"
- 2.out: "12"
- 3.inp: "-1 1"
- 3.out: "0"
```

**Bước 2: Tạo file ZIP**
```bash
cd aplusb_tests/
zip -r aplusb_tests.zip .
```

**Bước 3: Upload qua web interface**
1. Truy cập `/problem/aplusb/test_data`
2. Chọn file ZIP trong trường "Zipfile"
3. Hệ thống sẽ tự động:
   - Detect format Themis (*.inp, *.out)
   - Tạo 3 test cases tự động
   - Gán 1 điểm cho mỗi test case
4. Kiểm tra và chỉnh sửa nếu cần
5. Click "Apply!" để lưu

**Các format khác được hỗ trợ:**

**Format CMS:**
```
input.001, input.002, input.003
output.001, output.002, output.003
```

**Format Polygon:**
```
1, 2, 3 (input files)
1.a, 2.a, 3.a (output files)
```

**Format DMOJ (linh hoạt):**
```
test1.in, test2.in, test3.in
test1.out, test2.out, test3.out
```

### 2. Quản lý cuộc thi với ví dụ cụ thể

#### Ví dụ: Tạo cuộc thi "VNOJ Monthly Contest #1"
```
Thông tin cơ bản:
- Key: vnoj-monthly-1
- Name: VNOJ Monthly Contest #1
- Start time: 2024-01-15 14:00:00
- End time: 2024-01-15 17:00:00
- Format: IOI
- Access code: vnoj2024

Bài tập:
1. A+B Problem (100 điểm)
2. Fibonacci (200 điểm)
3. Prime Check (300 điểm)
4. Graph Traversal (500 điểm)
```

#### Workflow tạo cuộc thi:
1. **Tạo cuộc thi**: `/admin/judge/contest/add/`
2. **Cấu hình thời gian**: Sử dụng datetime picker
3. **Thêm bài tập**: Inline "Contest problems"
4. **Cấu hình rating**: Tick "is rated"
5. **Announcements**: Thêm thông báo trước khi bắt đầu

### 3. Quản lý người dùng với ví dụ cụ thể

#### Ví dụ: Tạo tài khoản học sinh
```
User info:
- Username: student001
- Email: student001@school.edu.vn
- First name: Nguyễn
- Last name: Văn A

Profile info:
- Display rank: Pupil
- Organizations: [Trường THPT ABC]
- Timezone: Asia/Ho_Chi_Minh
- Language: Vietnamese
- ACE theme: monokai
```

## Ví dụ Mock Data cụ thể

### 1. Mock Users và Profiles

```python
# Tạo users với roles khác nhau
users_data = [
    {
        'username': 'admin_user',
        'email': 'admin@vnoj.test',
        'first_name': 'Admin',
        'last_name': 'User',
        'is_staff': True,
        'is_superuser': True,
        'profile': {
            'display_rank': 'Admin',
            'timezone': 'Asia/Ho_Chi_Minh',
            'language': 'vi',
            'ace_theme': 'github'
        }
    },
    {
        'username': 'teacher_001',
        'email': 'teacher001@school.edu.vn',
        'first_name': 'Nguyễn',
        'last_name': 'Giáo Viên',
        'is_staff': True,
        'profile': {
            'display_rank': 'Expert',
            'vnoj_points': 2500,
            'rating': 1800,
            'timezone': 'Asia/Ho_Chi_Minh',
            'language': 'vi'
        }
    },
    {
        'username': 'student_001',
        'email': 'student001@school.edu.vn',
        'first_name': 'Trần',
        'last_name': 'Học Sinh',
        'profile': {
            'display_rank': 'Pupil',
            'vnoj_points': 850,
            'rating': 1200,
            'timezone': 'Asia/Ho_Chi_Minh',
            'language': 'vi'
        }
    }
]
```

### 2. Mock Organizations

```python
organizations_data = [
    {
        'name': 'Trường THPT Chuyên Lê Hồng Phong',
        'slug': 'lhp-high-school',
        'short_name': 'LHP',
        'is_open': False,
        'slots': 500,
        'access_code': 'lhp2024',
        'about': 'Trường THPT Chuyên Lê Hồng Phong - Nam Định',
        'creation_date': '2024-01-01',
        'registrant': 'teacher_001'
    },
    {
        'name': 'Đại học Bách Khoa Hà Nội',
        'slug': 'hust',
        'short_name': 'HUST',
        'is_open': True,
        'slots': 2000,
        'about': 'Trường Đại học Bách Khoa Hà Nội',
        'creation_date': '2024-01-01',
        'registrant': 'admin_user'
    }
]
```

### 3. Mock Problems

```python
problems_data = [
    {
        'code': 'aplusb',
        'name': 'A+B Problem',
        'description': '''
# A+B Problem

Cho hai số nguyên A và B. Tính tổng A + B.

## Input
Dòng đầu tiên chứa hai số nguyên A và B (-10^9 ≤ A, B ≤ 10^9).

## Output
In ra tổng A + B.

## Sample
### Input
```
1 2
```

### Output
```
3
```
        ''',
        'points': 100,
        'time_limit': 1.0,
        'memory_limit': 65536,
        'is_public': True,
        'date': '2024-01-01',
        'authors': ['admin_user'],
        'types': ['Beginner'],
        'group': 'Basic'
    },
    {
        'code': 'fibonacci',
        'name': 'Fibonacci Numbers',
        'description': '''
# Fibonacci Numbers

Tính số Fibonacci thứ n.

## Input
Một số nguyên n (1 ≤ n ≤ 45).

## Output
In ra số Fibonacci thứ n.

## Sample
### Input
```
10
```

### Output
```
55
```
        ''',
        'points': 200,
        'time_limit': 2.0,
        'memory_limit': 65536,
        'is_public': True,
        'date': '2024-01-02',
        'authors': ['teacher_001'],
        'types': ['Dynamic Programming'],
        'group': 'Intermediate'
    }
]
```

### 4. Mock Contests

```python
contests_data = [
    {
        'key': 'vnoj-monthly-1',
        'name': 'VNOJ Monthly Contest #1',
        'start_time': '2024-01-15 14:00:00',
        'end_time': '2024-01-15 17:00:00',
        'description': 'Cuộc thi hàng tháng đầu tiên của VNOJ',
        'is_visible': True,
        'is_rated': True,
        'rate_all': True,
        'format_name': 'ioi',
        'format_config': '{"penalty": 20}',
        'authors': ['admin_user'],
        'problems': [
            {'problem': 'aplusb', 'points': 100, 'order': 1},
            {'problem': 'fibonacci', 'points': 200, 'order': 2}
        ],
        'announcements': [
            {
                'title': 'Chào mừng!',
                'content': 'Chào mừng các bạn đến với cuộc thi đầu tiên!',
                'time': '2024-01-15 13:50:00'
            }
        ]
    },
    {
        'key': 'school-contest-lhp',
        'name': 'Cuộc thi Trường LHP',
        'start_time': '2024-01-20 08:00:00',
        'end_time': '2024-01-20 11:00:00',
        'description': 'Cuộc thi nội bộ trường LHP',
        'is_visible': True,
        'is_private': True,
        'private_contestants': True,
        'organizations': ['lhp-high-school'],
        'format_name': 'ioi',
        'authors': ['teacher_001']
    }
]
```

### 5. Mock Blog Posts

```python
blog_posts_data = [
    {
        'title': 'Chào mừng đến với VNOJ!',
        'slug': 'welcome-to-vnoj',
        'content': '''
# Chào mừng đến với VNOJ!

VNOJ (Vietnamese National Online Judge) là hệ thống chấm bài trực tuyến dành cho học sinh, sinh viên Việt Nam.

## Tính năng chính:
- Hàng nghìn bài tập từ cơ bản đến nâng cao
- Cuộc thi thường xuyên
- Hệ thống ranking và rating
- Hỗ trợ nhiều ngôn ngữ lập trình

Hãy bắt đầu hành trình học lập trình của bạn ngay hôm nay!
        ''',
        'visible': True,
        'sticky': True,
        'publish_on': '2024-01-01 00:00:00',
        'authors': ['admin_user']
    },
    {
        'title': 'Hướng dẫn sử dụng VNOJ cho người mới',
        'slug': 'guide-for-beginners',
        'content': '''
# Hướng dẫn sử dụng VNOJ cho người mới

## Bước 1: Đăng ký tài khoản
...

## Bước 2: Làm bài tập đầu tiên
...

## Bước 3: Tham gia cuộc thi
...
        ''',
        'visible': True,
        'publish_on': '2024-01-02 00:00:00',
        'authors': ['teacher_001']
    }
]
```

### 6. Mock Submissions

```python
submissions_data = [
    {
        'problem': 'aplusb',
        'user': 'student_001',
        'language': 'CPP17',
        'source': '''
#include <iostream>
using namespace std;

int main() {
    int a, b;
    cin >> a >> b;
    cout << a + b << endl;
    return 0;
}
        ''',
        'status': 'AC',
        'result': 'AC',
        'points': 100,
        'time': 0.001,
        'memory': 1024,
        'date': '2024-01-10 10:30:00'
    },
    {
        'problem': 'fibonacci',
        'user': 'student_001',
        'language': 'PYTHON3',
        'source': '''
def fibonacci(n):
    if n <= 2:
        return 1
    a, b = 1, 1
    for i in range(3, n + 1):
        a, b = b, a + b
    return b

n = int(input())
print(fibonacci(n))
        ''',
        'status': 'AC',
        'result': 'AC',
        'points': 200,
        'time': 0.050,
        'memory': 8192,
        'date': '2024-01-10 11:15:00'
    }
]
```

## Workflow thực tế

### 1. Workflow tạo cuộc thi hoàn chỉnh

#### Bước 1: Chuẩn bị bài tập
```
1. Tạo bài tập mới hoặc chọn từ bài tập có sẵn
2. Kiểm tra test cases
3. Cấu hình points phù hợp với cuộc thi
4. Test thử với submissions mẫu
```

#### Bước 2: Tạo cuộc thi
```
1. Truy cập /admin/judge/contest/add/
2. Điền thông tin cơ bản
3. Cấu hình thời gian (chú ý timezone)
4. Chọn format phù hợp (IOI/ICPC/AtCoder)
5. Cấu hình quyền truy cập
```

#### Bước 3: Thêm bài tập
```
1. Sử dụng inline "Contest problems"
2. Sắp xếp thứ tự từ dễ đến khó
3. Cấu hình points cho từng bài
4. Kiểm tra partial scoring
```

#### Bước 4: Chuẩn bị announcements
```
1. Thông báo chào mừng
2. Clarifications nếu cần
3. Thông báo kết thúc
```

#### Bước 5: Test cuộc thi
```
1. Tạo test account
2. Thử tham gia cuộc thi
3. Submit thử các bài
4. Kiểm tra scoreboard
```

### 2. Workflow quản lý tổ chức

#### Tạo tổ chức trường học
```
1. Tạo organization với thông tin trường
2. Cấu hình is_open = False (cần approval)
3. Thêm teachers làm admins
4. Cấu hình access_code
5. Tạo contests riêng cho trường
```

#### Quản lý học sinh
```
1. Học sinh đăng ký tài khoản
2. Request join organization
3. Teacher approve qua admin interface
4. Assign vào các contests phù hợp
```

### 3. Workflow chấm bài và feedback

#### Khi có submission lỗi
```
1. Kiểm tra judge status
2. Xem submission details
3. Rejudge nếu cần
4. Check test cases nếu có vấn đề
```

#### Khi cần rejudge hàng loạt
```
1. Filter submissions theo problem/contest
2. Select all
3. Sử dụng action "Rejudge submissions"
4. Monitor progress
```

## Troubleshooting thường gặp

### 1. Lỗi submissions không được chấm

**Triệu chứng**: Submissions stuck ở trạng thái "Queued"

**Nguyên nhân**:
- Judge servers offline
- Judge overload
- Network issues

**Giải pháp**:
```
1. Kiểm tra judge status: /admin/judge/judge/
2. Restart judge servers nếu cần
3. Check network connectivity
4. Rejudge submissions bị stuck
```

### 2. Lỗi không thể tạo cuộc thi

**Triệu chứng**: Permission denied khi tạo contest

**Nguyên nhân**:
- Thiếu quyền `create_private_contest`
- User không phải staff

**Giải pháp**:
```
1. Kiểm tra user permissions
2. Thêm quyền cần thiết
3. Đảm bảo user có is_staff = True
```

### 3. Lỗi test cases không load

**Triệu chứng**: Problem không chấm được, báo "No test cases"

**Nguyên nhân**:
- Test cases chưa upload
- File permissions sai
- Path không đúng
- ZIP file bị lỗi
- Format file không đúng

**Giải pháp**:
```
1. Kiểm tra ZIP file có hợp lệ không
2. Verify format file (*.inp/*.out, input.001/output.001, etc.)
3. Re-upload ZIP file qua /problem/<code>/test_data
4. Check file permissions trong thư mục problems/
5. Verify problem code matching
6. Kiểm tra console browser có lỗi JavaScript không
```

**Các lỗi thường gặp khi upload test cases:**

**Lỗi 1: "Files are not in the same format!"**
- **Nguyên nhân**: Mix nhiều format khác nhau trong 1 ZIP
- **Giải pháp**: Chỉ sử dụng 1 format duy nhất

**Lỗi 2: "The number of input files do not match output files!"**
- **Nguyên nhân**: Số lượng file input và output không bằng nhau
- **Giải pháp**: Đảm bảo mỗi input file có 1 output file tương ứng

**Lỗi 3: "Test file must be a ZIP file"**
- **Nguyên nhân**: File upload không phải ZIP hoặc bị corrupt
- **Giải pháp**: Tạo lại file ZIP với tool khác

**Lỗi 4: "Too many testcases"**
- **Nguyên nhân**: Vượt quá giới hạn số test cases
- **Giải pháp**: Giảm số test cases hoặc xin quyền `create_mass_testcases`

### 4. Lỗi rating không cập nhật

**Triệu chứng**: Rating không thay đổi sau contest

**Nguyên nhân**:
- Contest chưa được rate
- Lỗi trong rating calculation

**Giải pháp**:
```
1. Kiểm tra contest.is_rated = True
2. Run rating calculation manually
3. Check contest format config
4. Verify participant eligibility
```

## Best Practices

### 1. Bảo mật

```
✅ DO:
- Sử dụng 2FA cho tất cả admin accounts
- Thường xuyên backup database
- Monitor admin log entries
- Sử dụng strong passwords
- Limit admin permissions theo nguyên tắc least privilege

❌ DON'T:
- Share admin credentials
- Leave debug mode on production
- Ignore security updates
- Grant unnecessary permissions
```

### 2. Performance

```
✅ DO:
- Sử dụng database indexes
- Batch operations khi có thể
- Cache frequently accessed data
- Monitor query performance
- Use pagination for large datasets

❌ DON'T:
- Load all data at once
- Ignore N+1 queries
- Forget to optimize images
- Skip database maintenance
```

### 3. Content Management

```
✅ DO:
- Test problems trước khi publish
- Backup trước khi thay đổi lớn
- Sử dụng staging environment
- Version control cho important changes
- Document all customizations

❌ DON'T:
- Edit live contests
- Delete data without backup
- Change public problems without notice
- Ignore user feedback
```

### 4. User Experience

```
✅ DO:
- Provide clear error messages
- Use consistent naming conventions
- Test from user perspective
- Respond to support tickets promptly
- Keep documentation updated

❌ DON'T:
- Use technical jargon in user-facing messages
- Ignore accessibility requirements
- Make breaking changes without notice
- Forget to test mobile interface
```

## Kết luận

Admin interface của VNOJ cung cấp đầy đủ tính năng để quản lý một hệ thống online judge phức tạp. Với hệ thống phân quyền chi tiết, nhiều tính năng tùy chỉnh và các ví dụ mock data cụ thể, admin có thể quản lý hiệu quả mọi aspect của hệ thống.

### Những điểm cần nhớ:
1. **Luôn test trước khi deploy** - Sử dụng mock data để test
2. **Backup thường xuyên** - Đặc biệt trước khi thay đổi lớn
3. **Monitor hệ thống** - Theo dõi performance và errors
4. **Phân quyền cẩn thận** - Chỉ cấp quyền cần thiết
5. **Document changes** - Ghi lại mọi thay đổi quan trọng

Việc hiểu rõ các quyền hạn, workflow và có sẵn mock data để test là rất quan trọng để sử dụng hệ thống một cách an toàn và hiệu quả. 