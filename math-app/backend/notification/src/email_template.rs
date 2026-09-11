use crate::models::{ReportData, SubjectProgress};

const PINK: &str = "#FF6B9D";
const SOFT_PINK: &str = "#FFE0EC";
const DEEP_PURPLE: &str = "#4A5568";
const WHITE: &str = "#FFFFFF";

fn subject_info(subject_id: &str) -> (&'static str, &'static str, &'static str) {
    match subject_id {
        "numbers" => ("Toán", "Math", "🔢"),
        "geometry" => ("Hình học", "Geometry", "📐"),
        "measurement" => ("Đo lường", "Measurement", "📏"),
        "logic" => ("Logic", "Logic", "🧩"),
        "algebra" => ("Đại số", "Algebra", "🅰️"),
        "trigonometry" => ("Lượng giác", "Trigonometry", "📐"),
        "statistics" => ("Thống kê", "Statistics", "📊"),
        "vietnamese" => ("Tiếng Việt", "Vietnamese", "🇻🇳"),
        "english" => ("Tiếng Anh", "English", "🇬🇧"),
        _ => ("Khác", "Other", "📚"),
    }
}

fn progress_bar_html(pct: f64, color: &str) -> String {
    let clamped = pct.min(100.0).max(0.0);
    format!(
        r#"<div style="background-color:#E2E8F0;border-radius:8px;height:10px;overflow:hidden;margin:4px 0;">
  <div style="background-color:{};height:10px;border-radius:8px;width:{}%;"></div>
</div>"#,
        color,
        clamped as u32
    )
}

fn stats_row_vi(data: &ReportData) -> String {
    format!(
        r#"<table width="100%" cellpadding="0" cellspacing="0" style="margin:16px 0;">
  <tr>
    <td width="33%" align="center" style="padding:8px;">
      <div style="background-color:{};border-radius:12px;padding:16px 8px;">
        <div style="font-size:28px;font-weight:bold;color:{};">{}</div>
        <div style="font-size:12px;color:#718096;">bài đã học</div>
      </div>
    </td>
    <td width="33%" align="center" style="padding:8px;">
      <div style="background-color:{};border-radius:12px;padding:16px 8px;">
        <div style="font-size:28px;font-weight:bold;color:{};">⭐ {}</div>
        <div style="font-size:12px;color:#718096;">sao đạt được</div>
      </div>
    </td>
    <td width="33%" align="center" style="padding:8px;">
      <div style="background-color:{};border-radius:12px;padding:16px 8px;">
        <div style="font-size:28px;font-weight:bold;color:{};">🔥 {}</div>
        <div style="font-size:12px;color:#718096;">chuỗi ngày</div>
      </div>
    </td>
  </tr>
</table>"#,
        SOFT_PINK,
        PINK,
        data.lessons_completed_period,
        SOFT_PINK,
        PINK,
        data.total_stars,
        SOFT_PINK,
        PINK,
        data.current_streak,
    )
}

fn stats_row_en(data: &ReportData) -> String {
    format!(
        r#"<table width="100%" cellpadding="0" cellspacing="0" style="margin:16px 0;">
  <tr>
    <td width="33%" align="center" style="padding:8px;">
      <div style="background-color:{};border-radius:12px;padding:16px 8px;">
        <div style="font-size:28px;font-weight:bold;color:{};">{}</div>
        <div style="font-size:12px;color:#718096;">lessons done</div>
      </div>
    </td>
    <td width="33%" align="center" style="padding:8px;">
      <div style="background-color:{};border-radius:12px;padding:16px 8px;">
        <div style="font-size:28px;font-weight:bold;color:{};">⭐ {}</div>
        <div style="font-size:12px;color:#718096;">stars earned</div>
      </div>
    </td>
    <td width="33%" align="center" style="padding:8px;">
      <div style="background-color:{};border-radius:12px;padding:16px 8px;">
        <div style="font-size:28px;font-weight:bold;color:{};">🔥 {}</div>
        <div style="font-size:12px;color:#718096;">day streak</div>
      </div>
    </td>
  </tr>
</table>"#,
        SOFT_PINK,
        PINK,
        data.lessons_completed_period,
        SOFT_PINK,
        PINK,
        data.total_stars,
        SOFT_PINK,
        PINK,
        data.current_streak,
    )
}

fn subjects_section_vi(data: &ReportData) -> String {
    if data.subjects.is_empty() {
        return r#"<div style="text-align:center;padding:24px;color:#718096;font-size:14px;">
  Bé chưa học bài nào hôm nay 🐸
</div>"#
            .to_string();
    }

    let mut rows = String::new();
    for s in &data.subjects {
        let (_vi, _en, icon) = subject_info(&s.subject_id);
        rows.push_str(&format!(
            r#"<tr>
  <td style="padding:8px 0;">
    <div style="background-color:{};border-radius:10px;padding:12px;">
      <div style="display:flex;align-items:center;margin-bottom:4px;">
        <span style="font-size:20px;margin-right:8px;">{}</span>
        <span style="font-weight:bold;color:{};">{}</span>
        <span style="margin-left:auto;font-size:13px;color:#718096;">{} bài · ⭐{}</span>
      </div>
      {}
      <span style="font-size:12px;color:#718096;">{:.0}% hoàn thành</span>
    </div>
  </td>
</tr>"#,
            SOFT_PINK,
            icon,
            DEEP_PURPLE,
            s.name_vi,
            s.completed,
            s.stars,
            progress_bar_html(s.completion_pct, PINK),
            s.completion_pct,
        ));
    }

    format!(
        r#"<table width="100%" cellpadding="0" cellspacing="0" style="margin:16px 0;">{}</table>"#,
        rows
    )
}

fn subjects_section_en(data: &ReportData) -> String {
    if data.subjects.is_empty() {
        return r#"<div style="text-align:center;padding:24px;color:#718096;font-size:14px;">
  No lessons today 🐸
</div>"#
            .to_string();
    }

    let mut rows = String::new();
    for s in &data.subjects {
        let (_vi, _en, icon) = subject_info(&s.subject_id);
        rows.push_str(&format!(
            r#"<tr>
  <td style="padding:8px 0;">
    <div style="background-color:{};border-radius:10px;padding:12px;">
      <div style="display:flex;align-items:center;margin-bottom:4px;">
        <span style="font-size:20px;margin-right:8px;">{}</span>
        <span style="font-weight:bold;color:{};">{}</span>
        <span style="margin-left:auto;font-size:13px;color:#718096;">{} lessons · ⭐{}</span>
      </div>
      {}
      <span style="font-size:12px;color:#718096;">{:.0}% complete</span>
    </div>
  </td>
</tr>"#,
            SOFT_PINK,
            icon,
            DEEP_PURPLE,
            s.name_en,
            s.completed,
            s.stars,
            progress_bar_html(s.completion_pct, PINK),
            s.completion_pct,
        ));
    }

    format!(
        r#"<table width="100%" cellpadding="0" cellspacing="0" style="margin:16px 0;">{}</table>"#,
        rows
    )
}

fn achievements_section_vi(data: &ReportData) -> String {
    if data.new_achievements.is_empty() {
        return String::new();
    }
    let badges: String = data
        .new_achievements
        .iter()
        .map(|a| {
            format!(
                r#"<span style="display:inline-block;background-color:{};color:{};border-radius:20px;padding:6px 14px;margin:4px;font-size:13px;font-weight:bold;">🏅 {}</span>"#,
                SOFT_PINK, PINK, a
            )
        })
        .collect::<Vec<_>>()
        .join("");

    format!(
        r#"<div style="margin:16px 0;">
  <h3 style="color:{};">🏆 Thành tích mới</h3>
  <div style="text-align:center;padding:8px;">{}</div>
</div>"#,
        DEEP_PURPLE, badges
    )
}

fn achievements_section_en(data: &ReportData) -> String {
    if data.new_achievements.is_empty() {
        return String::new();
    }
    let badges: String = data
        .new_achievements
        .iter()
        .map(|a| {
            format!(
                r#"<span style="display:inline-block;background-color:{};color:{};border-radius:20px;padding:6px 14px;margin:4px;font-size:13px;font-weight:bold;">🏅 {}</span>"#,
                SOFT_PINK, PINK, a
            )
        })
        .collect::<Vec<_>>()
        .join("");

    format!(
        r#"<div style="margin:16px 0;">
  <h3 style="color:{};">🏆 New Achievements</h3>
  <div style="text-align:center;padding:8px;">{}</div>
</div>"#,
        DEEP_PURPLE, badges
    )
}

fn cta_button_vi() -> String {
    format!(
        r#"<div style="text-align:center;margin:24px 0;">
  <a href="https://sekklings.com/app" style="display:inline-block;background-color:{};color:{};text-decoration:none;font-weight:bold;padding:14px 32px;border-radius:30px;font-size:16px;">Xem chi tiết</a>
</div>"#,
        PINK, WHITE
    )
}

fn cta_button_en() -> String {
    format!(
        r#"<div style="text-align:center;margin:24px 0;">
  <a href="https://sekklings.com/app" style="display:inline-block;background-color:{};color:{};text-decoration:none;font-weight:bold;padding:14px 32px;border-radius:30px;font-size:16px;">View details</a>
</div>"#,
        PINK, WHITE
    )
}

fn footer_vi() -> String {
    format!(
        r#"<div style="text-align:center;padding:20px 0;color:#A0AEC0;font-size:12px;border-top:1px solid #E2E8F0;margin-top:24px;">
  <p>🐸 <strong style="color:{};">HocVui</strong> — Toán vui cho bé</p>
  <p><a href="mailto:contact@sekklings.com" style="color:#A0AEC0;">contact@sekklings.com</a></p>
  <p><a href="https://sekklings.com/unsubscribe" style="color:#A0AEC0;">Hủy đăng ký</a></p>
</div>"#,
        PINK
    )
}

fn footer_en() -> String {
    format!(
        r#"<div style="text-align:center;padding:20px 0;color:#A0AEC0;font-size:12px;border-top:1px solid #E2E8F0;margin-top:24px;">
  <p>🐸 <strong style="color:{};">HocVui</strong> — Fun math for kids</p>
  <p><a href="mailto:contact@sekklings.com" style="color:#A0AEC0;">contact@sekklings.com</a></p>
  <p><a href="https://sekklings.com/unsubscribe" style="color:#A0AEC0;">Unsubscribe</a></p>
</div>"#,
        PINK
    )
}

fn header_html(title: &str) -> String {
    format!(
        r#"<div style="background-color:{};padding:24px;text-align:center;border-radius:12px 12px 0 0;">
  <div style="font-size:32px;">🐸</div>
  <div style="font-size:24px;font-weight:bold;color:{};">HocVui</div>
  <div style="font-size:16px;color:{};">{}</div>
</div>"#,
        PINK, WHITE, WHITE, title
    )
}

fn wrap_html(inner: &str) -> String {
    format!(
        r#"<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background-color:#F7FAFC;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F7FAFC;">
    <tr>
      <td align="center" style="padding:20px;">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;background-color:{};border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
          <tr><td style="padding:0;">{}</td></tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"#,
        WHITE, inner
    )
}

pub fn render_daily_report_vi(data: &ReportData) -> String {
    let title = format!("Báo cáo học tập — {}", data.period_label);
    let body = format!(
        r#"{}{}
<div style="padding:20px;">
  <p style="color:{};font-size:15px;">Chào phụ huynh của <strong>{}</strong>,</p>
  <p style="color:{};font-size:14px;">Đây là báo cáo học tập {} của bé.</p>
  {}
  <h3 style="color:{};">📚 Tiến độ theo môn</h3>
  {}
  {}
  {}
</div>"#,
        header_html(&title),
        stats_row_vi(data),
        DEEP_PURPLE,
        data.user_name,
        DEEP_PURPLE,
        data.period_label,
        achievements_section_vi(data),
        DEEP_PURPLE,
        subjects_section_vi(data),
        cta_button_vi(),
        footer_vi(),
    );
    wrap_html(&body)
}

pub fn render_daily_report_en(data: &ReportData) -> String {
    let title = format!("Learning Report — {}", data.period_label);
    let body = format!(
        r#"{}{}
<div style="padding:20px;">
  <p style="color:{};font-size:15px;">Hello, parent of <strong>{}</strong>,</p>
  <p style="color:{};font-size:14px;">Here is your child's learning report for {}.</p>
  {}
  <h3 style="color:{};">📚 Progress by Subject</h3>
  {}
  {}
  {}
</div>"#,
        header_html(&title),
        stats_row_en(data),
        DEEP_PURPLE,
        data.user_name,
        DEEP_PURPLE,
        data.period_label,
        achievements_section_en(data),
        DEEP_PURPLE,
        subjects_section_en(data),
        cta_button_en(),
        footer_en(),
    );
    wrap_html(&body)
}

pub fn render_weekly_report_vi(data: &ReportData) -> String {
    let title = format!("Báo cáo học tập — {}", data.period_label);
    let body = format!(
        r#"{}{}
<div style="padding:20px;">
  <p style="color:{};font-size:15px;">Chào phụ huynh của <strong>{}</strong>,</p>
  <p style="color:{};font-size:14px;">Đây là báo cáo học tập {} của bé.</p>
  <p style="color:#718096;font-size:13px;">Tổng số bài đã hoàn thành: <strong>{}</strong> · Tổng điểm: <strong>{}</strong></p>
  {}
  <h3 style="color:{};">📚 Tiến độ theo môn</h3>
  {}
  {}
  {}
</div>"#,
        header_html(&title),
        stats_row_vi(data),
        DEEP_PURPLE,
        data.user_name,
        DEEP_PURPLE,
        data.period_label,
        data.lessons_completed_total,
        data.total_score,
        achievements_section_vi(data),
        DEEP_PURPLE,
        subjects_section_vi(data),
        cta_button_vi(),
        footer_vi(),
    );
    wrap_html(&body)
}

pub fn render_weekly_report_en(data: &ReportData) -> String {
    let title = format!("Learning Report — {}", data.period_label);
    let body = format!(
        r#"{}{}
<div style="padding:20px;">
  <p style="color:{};font-size:15px;">Hello, parent of <strong>{}</strong>,</p>
  <p style="color:{};font-size:14px;">Here is your child's weekly learning report for {}.</p>
  <p style="color:#718096;font-size:13px;">Total lessons completed: <strong>{}</strong> · Total score: <strong>{}</strong></p>
  {}
  <h3 style="color:{};">📚 Progress by Subject</h3>
  {}
  {}
  {}
</div>"#,
        header_html(&title),
        stats_row_en(data),
        DEEP_PURPLE,
        data.user_name,
        DEEP_PURPLE,
        data.period_label,
        data.lessons_completed_total,
        data.total_score,
        achievements_section_en(data),
        DEEP_PURPLE,
        subjects_section_en(data),
        cta_button_en(),
        footer_en(),
    );
    wrap_html(&body)
}